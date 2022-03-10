@import Cocoa ;
@import LuaSkin ;
@import Accelerate ;
@import QuartzCore ;

#import "TouchBar.h"

/// === hs.touchbar.virtual ===
///
/// This submodule provides support for creating a virtual touchbar which can be displayed on the users screen.
///
/// While this submodule will be primarily of interest to those without a touchbar enabled mac, it can also be used on machines which *do* have a touchbar and is in fact required if you wish to create an image of the current contents of the touchbar -- see [hs.touchbar:image](#image).
///
/// This module is very experimental and is still under development, so the exact functions and methods may be subject to change without notice.
///
/// This submodule is based in heavily on code from the following sources:
/// * https://github.com/bikkelbroeders/TouchBarDemoApp - For the virtual touchbar itself (see [hs.touchbar.new](#new)). Unlike the code found at this link, we only support displaying the touch bar window on your computer screen and not on an attached iOS device.
/// * https://github.com/steventroughtonsmith/TouchBarScreenshotter/blob/master/TouchBarScreenshotter - for the code to create an image of the touchbar (see [hs.touchbar:image](#image))

static const char *USERDATA_TAG = "hs.touchbar.virtual" ;
static int        refTable      = LUA_NOREF ;
static int        initialDFRStatus ;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static inline NSRect RectWithFlippedYCoordinate(NSRect theRect) {
    return NSMakeRect(theRect.origin.x,
                      [[NSScreen screens][0] frame].size.height - theRect.origin.y - theRect.size.height,
                      theRect.size.width,
                      theRect.size.height) ;
}

@interface ASMTouchBarView : NSView
@property CGDisplayStreamRef stream ;
@property NSView             *displayView ;
@property BOOL               passMouseEvents ;
@property CGContextRef       context ;
@end

@implementation ASMTouchBarView {}

- (instancetype) init {
    self = [super init] ;
    if(self != nil) {
        _passMouseEvents = YES ;
        _displayView = [NSView new] ;

        CGSize tbScreenSize = DFRGetScreenSize() ;

        _displayView.frame = NSMakeRect(5, 5, tbScreenSize.width, tbScreenSize.height) ;
        _displayView.wantsLayer = YES ;
        [self addSubview:_displayView] ;

        _stream = SLSDFRDisplayStreamCreate(NULL, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status,
                                                                               __unused uint64_t displayTime,
                                                                               IOSurfaceRef frameSurface,
                                                                               __unused CGDisplayStreamUpdateRef updateRef) {
            if (status != kCGDisplayStreamFrameStatusFrameComplete) return ;
            self->_displayView.layer.contents = (__bridge id)(frameSurface) ;

// https://github.com/steventroughtonsmith/TouchBarScreenshotter/blob/master/TouchBarScreenshotter/AppDelegate.m
            IOSurfaceRef surface = frameSurface ;

            IOSurfaceLock(surface, kIOSurfaceLockReadOnly, nil) ;
            void   *frameBase  = IOSurfaceGetBaseAddress(surface) ;
            size_t bytesPerRow = IOSurfaceGetBytesPerRow(surface) ;
            size_t height      = IOSurfaceGetHeight(surface) ;
            size_t width       = IOSurfaceGetWidth(surface) ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3) ;
#pragma clang diagnostic pop

            vImage_Buffer src ;
            src.height   = height ;
            src.width    = width ;
            src.rowBytes = bytesPerRow ;
            src.data     = frameBase ;

            vImage_Buffer dest ;
            dest.height   = height ;
            dest.width    = width ;
            dest.rowBytes = bytesPerRow ;
            dest.data     = malloc(bytesPerRow*height) ;

            // Swap pixel channels from BGRA to RGBA.
            const uint8_t map[4] = { 2, 1, 0, 3 } ;
            vImagePermuteChannels_ARGB8888(&src, &dest, map, kvImageNoFlags) ;

            self->_context = CGBitmapContextCreate (dest.data,
                                             width,
                                             height,
                                             8,
                                             bytesPerRow,
                                             colorSpace,
                                             kCGImageAlphaPremultipliedLast) ;

            CGColorSpaceRelease(colorSpace) ;
            IOSurfaceUnlock(surface, kIOSurfaceLockReadOnly, nil) ;

            if (self->_context == NULL) {
                [LuaSkin logDebug:[NSString stringWithFormat:@"%s:unable to create context for touchbar image creation", USERDATA_TAG]] ;
            }

        }) ;

        // Likewise, CGDisplayStreamStop will pause updates
        CGDisplayStreamStart(_stream) ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:_displayView.frame
                                                           options:( NSTrackingMouseEnteredAndExited |
                                                                     NSTrackingActiveAlways |
                                                                     NSTrackingInVisibleRect )
                                                             owner:self
                                                          userInfo:nil]] ;
#pragma clang diagnostic pop
    }

    return self ;
}

- (void)commonMouseEvent:(NSEvent *)event {
    if (_passMouseEvents) {
        NSPoint location = [_displayView convertPoint:[event locationInWindow] fromView:nil] ;
        DFRFoundationPostEventWithMouseActivity(event.type, location) ;
    }
}

- (void)mouseDown:(NSEvent *)event {
    [self commonMouseEvent:event] ;
}

- (void)mouseUp:(NSEvent *)event {
    [self commonMouseEvent:event] ;
}

- (void)mouseDragged:(NSEvent *)event {
    [self commonMouseEvent:event] ;
}

- (void)stopStreaming {
    if (_stream) CGDisplayStreamStop(_stream) ;
}

- (void)startStreaming {
    if (_stream) CGDisplayStreamStart(_stream) ;
}

@end

@interface NSWindow (Private)
- (void )_setPreventsActivation:(bool)preventsActivation ;
@end

@interface ASMTouchBarWindow : NSWindow
@property CGFloat inactiveAlpha ;
@property int     callbackRef ;
@property int     selfRefCount ;
@end

@implementation ASMTouchBarWindow

- (instancetype)init {
    self = [super init] ;
    if(self != nil) {
        _inactiveAlpha = .5 ;
        _callbackRef   = LUA_NOREF ;
        _selfRefCount  = 0 ;

        self.styleMask                  = NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView ;
        self.titlebarAppearsTransparent = YES ;
        self.titleVisibility            = NSWindowTitleHidden ;
        self.movable                    = NO ;
        self.acceptsMouseMovedEvents    = YES ;
        self.movableByWindowBackground  = YES ;
        self.level                      = CGWindowLevelForKey(kCGAssistiveTechHighWindowLevelKey) ;
        self.collectionBehavior         = (NSWindowCollectionBehaviorCanJoinAllSpaces |
                                           NSWindowCollectionBehaviorStationary |
                                           NSWindowCollectionBehaviorIgnoresCycle |
                                           NSWindowCollectionBehaviorFullScreenDisallowsTiling) ;
        self.backgroundColor            = [NSColor blackColor] ;

        [self standardWindowButton:NSWindowCloseButton].hidden       = YES ;
        [self standardWindowButton:NSWindowZoomButton].hidden        = YES ;
        [self standardWindowButton:NSWindowZoomButton].hidden        = YES ;
        [self standardWindowButton:NSWindowMiniaturizeButton].hidden = YES ;
        [self _setPreventsActivation:YES] ;

        ASMTouchBarView *tbView = [ASMTouchBarView new] ;
        CGSize tbScreenSize = DFRGetScreenSize() ;
        [self setFrame:NSMakeRect(0, 0, tbScreenSize.width + 10, tbScreenSize.height + 10) display:YES] ;
        self.contentView                = tbView ;
    }

    return self ;
}

- (BOOL)canBecomeMainWindow {
    return NO ;
}

- (BOOL)canBecomeKeyWindow {
    return NO ;
}

- (void)callbackWith:(NSString *)message {
    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin sharedWithState:NULL] ;
        [skin pushLuaRef:refTable ref:_callbackRef] ;
        [skin pushNSObject:self] ;
        [skin pushNSObject:message] ;
        if (![skin protectedCallAndTraceback:2 nresults:0]) {
            [skin logError:[NSString stringWithFormat:@"%s:callback error:%@", USERDATA_TAG, [skin toNSObjectAtIndex:-1]]] ;
            lua_pop([skin L], 1) ;
        }
    }
}

- (void)mouseExited:(__unused NSEvent *)theEvent {
    self.alphaValue = _inactiveAlpha ;
    [self callbackWith:@"didExit"] ;
}

- (void)mouseEntered:(__unused NSEvent *)theEvent {
    self.alphaValue = 1.0 ;
    [self callbackWith:@"didEnter"] ;
}

@end

#pragma mark - Module Functions

/// hs.touchbar.virtual.new() -> touchbarObject | nil
/// Function
/// Creates a new touchbarObject representing a window which displays the Apple Touch Bar.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the touchbarObject or nil if one could not be created
///
/// Notes:
///  * The most common reason a touchbarObject cannot be created is if your macOS version is not new enough. Type the following into your Hammerspoon console to check: `require("hs.touchbar").supported(true)`.
static int touchbar_virtual_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;

    // All examples of the virtual touchbar set this to 2 to enable, but sampling a few users machines that come with the touchbar,
    // it seems like the machines with a physical touchbar have the value at 3; however, forcing it to 2 on the 16" models borks the
    // touchbar (it didn't seem to affect anything with the earlier models, even though they're also reporting 3) so, lets only set it
    // when the machine doesn't have a physical touchbar at all...
    if ((initialDFRStatus & 0x01) == 0) DFRSetStatus(2) ;
    [skin pushNSObject:[ASMTouchBarWindow new]] ;
    return 1 ;
}

#pragma mark - Module Methods

/// hs.touchbar.virtual:show([duration]) -> touchbarObject
/// Method
/// Display the touch bar window with an optional fade-in delay.
///
/// Parameters:
///  * `duration` - an optional number, default 0.0, specifying the fade-in time for the touch bar window.
///
/// Returns:
///  * the touchbarObject
///
/// Notes:
///  * This method does nothing if the window is already visible.
static int touchbar_virtual_show(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;
    NSTimeInterval    duration  = (lua_gettop(L) == 2) ? lua_tonumber(L, 2) : 0.0 ;

    if (touchbar.visible == NO) {
        CGFloat initialAlpha = [touchbar.contentView hitTest:[NSEvent mouseLocation]] ? 1.0 : touchbar.inactiveAlpha ;
        touchbar.alphaValue = (duration > 0) ? 0.0 : initialAlpha ;
        [(ASMTouchBarView *)touchbar.contentView startStreaming] ;
        [touchbar setIsVisible:YES] ;
        if (duration > 0.0) {
            [NSAnimationContext beginGrouping] ;
            [[NSAnimationContext currentContext] setDuration:duration] ;
            [[touchbar animator] setAlphaValue:1.0] ;
            [NSAnimationContext endGrouping] ;
        }
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchbar.virtual:level([level]) -> touchbarObject | currentValue
/// Method
/// Get or set the window level for the virtual touchbar.
///
/// Parameters:
///  * `level` - an optional integer, default 1500, specifying the new window level for the virtual touchbar. See `hs.canvas.windowLevels](#windowLevels` for the numeric values for standard window levels.
///
/// Returns:
///  * If an argument is provided, the virtual touchbar object; otherwise the current value.
///
/// Notes:
///  * If you hide the Dock and want the virtual touchbar at the bottom of the screen, setting the touchbar window level to 20 allows the Dock to appear over the touchbar when you move the mouse pointer down far enough to raise the Dock.
static int touchbar_virtual_level(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, touchbar.level) ;
    } else {
        lua_Integer targetLevel = lua_tointeger(L, 2) ;

        targetLevel = (targetLevel < CGWindowLevelForKey(kCGMinimumWindowLevelKey)) ? CGWindowLevelForKey(kCGMinimumWindowLevelKey) : ((targetLevel > CGWindowLevelForKey(kCGMaximumWindowLevelKey)) ? CGWindowLevelForKey(kCGMaximumWindowLevelKey) : targetLevel) ;
        touchbar.level = targetLevel ;
        lua_pushvalue(L, 1) ;
    }

    return 1 ;
}

/// hs.touchbar.virtual:streaming(state) -> touchbarObject
/// Method
/// Enable or disable updates to the virtual touchbar.
///
/// Parameters:
///  * `state` - a boolean specifying whether or not the virtual touchbar window should be updated to reflect the current contents of the touchbar.
///
/// Returns:
///  * the touchbarObject
///
/// Notes:
///  * This method is invoked automatically with `true` when [hs.touchbar.virtual:show](#show) is invoked and with `false` when [hs.touchbar.virtual:hide](#hide) is invoked.
///  * In order for [hs.touchbar.virtual:image](#image) to be able to capture a snapshot of the touchbar, the virtual touchbar must be currently receiving updates; this method will allow you to enable the updates even if the virtual touchbar is not currently visible on the screen (for example, if you have a physical touchbar on your laptop and do not wish to clutter the display with a duplicate of what you already posses).
static int touchbar_virtual_streaming(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;
    if (lua_toboolean(L, 2)) {
        [(ASMTouchBarView *)touchbar.contentView startStreaming] ;
    } else {
        [(ASMTouchBarView *)touchbar.contentView stopStreaming] ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchbar.virtual:hide([duration]) -> touchbarObject
/// Method
/// Display the touch bar window with an optional fade-out delay.
///
/// Parameters:
///  * `duration` - an optional number, default 0.0, specifying the fade-out time for the touch bar window.
///
/// Returns:
///  * the touchbarObject
///
/// Notes:
///  * This method does nothing if the window is already hidden.
///  * The value used in the sample code referenced in the module header is 0.1.
static int touchbar_virtual_hide(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;
    NSTimeInterval    duration  = (lua_gettop(L) == 2) ? lua_tonumber(L, 2) : 0.0 ;

    if (touchbar.visible == YES) {
        [(ASMTouchBarView *)touchbar.contentView stopStreaming] ;
        if (duration > 0.0) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                context.duration = duration ;
                [[touchbar animator] setAlphaValue:0.0] ;
            } completionHandler:^{
                if(touchbar.alphaValue == 0.0) {
                    [touchbar setIsVisible:NO] ;
                }
            }] ;
        } else {
            touchbar.alphaValue = 0.0 ;
            [touchbar setIsVisible:NO] ;
        }
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchbar.virtual:topLeft([point]) -> table | touchbarObject
/// Method
/// Get or set the top-left of the touch bar window.
///
/// Parameters:
///  * `point` - an optional table specifying where the top left of the touch bar window should be moved to.
///
/// Returns:
///  * if a value is provided, returns the touchbarObject; otherwise returns the current value.
///
/// Notes:
///  * A point table is a table with at least `x` and `y` key-value pairs which specify the coordinates on the computer screen where the window should be moved to.  Hammerspoon considers the upper left corner of the primary screen to be { x = 0.0, y = 0.0 }.
static int touchbar_virtual_topLeft(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    NSRect frame = RectWithFlippedYCoordinate(touchbar.frame) ;
    if (lua_gettop(L) == 1) {
        [skin pushNSPoint:frame.origin] ;
    } else {
        NSPoint point  = [skin tableToPointAtIndex:2] ;
        frame.origin.x = point.x ;
        frame.origin.y = point.y ;
        [touchbar setFrame:RectWithFlippedYCoordinate(frame) display:YES animate:NO] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:getFrame() -> table
/// Method
/// Gets the frame of the touch bar window
///
/// Parameters:
///  * None
///
/// Returns:
///  * a frame table with key-value pairs specifying the top left corner of the touch bar window and its width and height.
///
/// Notes:
///  * A frame table is a table with at least `x`, `y`, `h` and `w` key-value pairs which specify the coordinates on the computer screen of the window and its width (w) and height(h).
///  * This allows you to get the frame so that you can include its height and width in calculations - it does not allow you to change the size of the touch bar window itself.
static int touchbar_virtual_getFrame(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    NSRect frame = RectWithFlippedYCoordinate(touchbar.frame) ;
    if (lua_gettop(L) == 1) {
        [skin pushNSRect:frame] ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:isVisible() -> boolean
/// Method
/// Returns a boolean indicating whether or not the touch bar window is current visible.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean specifying whether the touch bar window is visible (true) or not (false).
static int touchbar_virtual_isVisible(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;
    lua_pushboolean(L, touchbar.visible) ;
    return 1 ;
}

/// hs.touchbar.virtual:inactiveAlpha([alpha]) -> number | touchbarObject
/// Method
/// Get or set the alpha value for the touch bar window when the mouse is not hovering over it.
///
/// Parameters:
///  * alpha - an optional number between 0.0 and 1.0 inclusive specifying the alpha value for the touch bar window when the mouse is not over it.  Defaults to 0.5.
///
/// Returns:
///  * if a value is provided, returns the touchbarObject; otherwise returns the current value
static int touchbar_virtual_inactiveAlpha(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, touchbar.inactiveAlpha) ;
    } else {
        CGFloat newAlpha = luaL_checknumber(L, 2) ;
        touchbar.inactiveAlpha = ((newAlpha < 0.0) ? 0.0 : ((newAlpha > 1.0) ? 1.0 : newAlpha)) ;
        touchbar.alphaValue = [touchbar.contentView hitTest:[NSEvent mouseLocation]] ? 1.0 : touchbar.inactiveAlpha ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:movable([state]) -> boolean | touchbarObject
/// Method
/// Get or set whether or not the touch bar window is movable by clicking on it and holding down the mouse button while moving the mouse.
///
/// Parameters:
///  * `state` - an optional boolean which specifies whether the touch bar window is movable (true) or not (false).  Default false.
///
/// Returns:
///  * if an argument is provided, returns the touchbarObject; otherwise returns the current value.
///
/// Notes:
///  * While the touch bar is movable, actions which require moving the mouse while clicking on the touch bar are not accessible.
///  * See also [hs.touchbar.virtual:acceptsMouseEvents](#acceptsMouseEvents).
static int touchbar_virtual_movable(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, touchbar.movable) ;
    } else {
        touchbar.movable = (int)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:acceptsMouseEvents([state]) -> boolean | touchbarObject
/// Method
/// Get or set whether or not the touch bar accepts mouse events.
///
/// Parameters:
///  * `state` - an optional boolean which specifies whether the touch bar accepts mouse events (true) or not (false).  Default true.
///
/// Returns:
///  * if an argument is provided, returns the touchbarObject; otherwise returns the current value.
///
/// Notes:
///  * This method can be used to prevent mouse clicks in the touch bar from triggering the touch bar buttons.
///  * This can be useful when [hs.touchbar.virtual:movable](#movable) is set to true to prevent accidentally triggering an action.
static int touchbar_virtual_acceptsMouseEvents(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, ((ASMTouchBarView *)touchbar.contentView).passMouseEvents) ;
    } else {
        ((ASMTouchBarView *)touchbar.contentView).passMouseEvents = (int)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:backgroundColor([color]) -> color | touchbarObject
/// Method
/// Get or set the background color for the touch bar window.
///
/// Parameters:
///  * `color` - an optional color table as defined in `hs.drawing.color` specifying the background color for the touch bar window.  Defaults to black, i.e. `{ white = 0.0, alpha = 1.0 }`.
///
/// Returns:
///  * if an argument is provided, returns the touchbarObject; otherwise returns the current value.
///
/// Notes:
///  * The visual effect of this method is to change the border color around the touch bar -- the touch bar itself remains the color as defined by the application which is providing the current touch bar items for display.
static int touchbar_virtual_backgroundColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:touchbar.backgroundColor] ;
    } else {
        NSColor *newColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        if (newColor) {
            touchbar.backgroundColor = newColor ;
        } else {
            touchbar.backgroundColor = [NSColor blackColor] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchbar.virtual:setCallback(fn) -> touchbarObject
/// Method
/// Sets the callback function for the touch bar window.
///
/// Parameters:
///  * `fn` - a function to set as the callback for the touch bar window, or nil to remove the existing callback function.
///
/// Returns:
///  * the touchbarObject
///
/// Notes:
///  * The function should expect 2 arguments and return none.  The arguments will be one of the following:
///
///    * obj, "didEnter" - indicates that the mouse pointer has entered the window containing the touch bar
///      * `obj`     - the touchbarObject the callback is for
///      * `message` - the message to the callback, in this case "didEnter"
///
///    * obj, "didExit" - indicates that the mouse pointer has exited the window containing the touch bar
///      * `obj`     - the touchbarObject the callback is for
///      * `message` - the message to the callback, in this case "didEnter"
static int touchbar_virtual_setCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;

    touchbar.callbackRef = [skin luaUnref:refTable ref:touchbar.callbackRef] ;
    if (lua_type(L, 2) != LUA_TNIL) {
        lua_pushvalue(L, 2) ;
        touchbar.callbackRef = [skin luaRef:refTable] ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchbar.virtual:image() -> hs.image Object | nil
/// Method
/// Returns an image of the current contents of the virtual touchbar, or nil if the virtual touchbar is not currently being updated.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an `hs.image` object of the current contents of the virtual touchbar, or nil if the virtual touchbar is not currently being updated.
///
/// Notes:
///  * By default, the virtual touchbar is only receiving upates when it is visible on the screen -- [hs.touchbar.virtual:show](#show). If you wish to take a snapshot of the virtual touchbar but do not want it to be visible on the screen, you must invoke [hs.touchbar.virtual:streaming(true)](#streaming) before using this method.
///    * Note that it may take a second or two after invoking [hs.touchbar.virtual:streaming(true)](#streaming) before the first image can be made, so you should check that the return value is not `nil` before using the image; you can use something like the following:
///
///          myTouchbar = require("hs.touchbar").viritual.new():streaming(true)
///          hs.timer.waitUntil(function() return myTouchbar:image() end, function()
///             -- whatever you need now that images can be captured
///          end)
///
///    * Once streaming has been enabled and the first image is received, subsequent image requests will continue to succeed until streaming is stopped with [hs.touchbar.virtual:streaming(false)](#streaming) or [hs.touchbar.virtual:hide()](#hide).
static int touchbar_virtual_asImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchBarWindow *touchbar = [skin toNSObjectAtIndex:1] ;
    ASMTouchBarView   *touchBarView = touchbar.contentView ;


    CGImageRef imgRef  = CGBitmapContextCreateImage(touchBarView.context) ;
    if (imgRef == NULL) {
        lua_pushnil(L) ;
    } else {
        CGSize     imgSize = DFRGetScreenSize() ;

        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imgRef] ;
        NSImage          *image    = [[NSImage alloc] initWithSize:imgSize] ;
        [image addRepresentation:imageRep];

        [skin pushNSObject:image] ;
    }
    return 1 ;
}


//       during __gc do we need to remove callback from dispatch queue?

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushASMTouchBarWindow(lua_State *L, id obj) {
    ASMTouchBarWindow *value = obj ;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(ASMTouchBarWindow *)) ;
    *valuePtr = (__bridge_retained void *)value ;
    luaL_getmetatable(L, USERDATA_TAG) ;
    lua_setmetatable(L, -2) ;
    return 1 ;
}

static id toASMTouchBarWindowFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    ASMTouchBarWindow *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge ASMTouchBarWindow, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
//     ASMTouchBarWindow *obj = [skin luaObjectAtIndex:1 toClass:"ASMTouchBarWindow"] ;
    NSString *title = @"TouchBar" ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin sharedWithState:L] ;
        ASMTouchBarWindow *obj1 = [skin luaObjectAtIndex:1 toClass:"ASMTouchBarWindow"] ;
        ASMTouchBarWindow *obj2 = [skin luaObjectAtIndex:2 toClass:"ASMTouchBarWindow"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    ASMTouchBarWindow *obj = get_objectFromUserdata(__bridge_transfer ASMTouchBarWindow, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin sharedWithState:L] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            // not sure what else to do to cleanup... if I do [obj close] on the window, it crashes...
            obj.alphaValue = 0.0 ;
            [obj setIsVisible:NO] ;
            [(ASMTouchBarView *)obj.contentView stopStreaming] ;
            obj = nil ;
        }
    }

    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

static int meta_gc(lua_State* __unused L) {
    // here we just want to go back to whatever state we were in before this module loaded
    if (DFRGetStatus() != initialDFRStatus) DFRSetStatus(initialDFRStatus) ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"show",               touchbar_virtual_show},
    {"hide",               touchbar_virtual_hide},
    {"topLeft",            touchbar_virtual_topLeft},
    {"getFrame",           touchbar_virtual_getFrame},
    {"inactiveAlpha",      touchbar_virtual_inactiveAlpha},
    {"isVisible",          touchbar_virtual_isVisible},
    {"movable",            touchbar_virtual_movable},
    {"backgroundColor",    touchbar_virtual_backgroundColor},
    {"setCallback",        touchbar_virtual_setCallback},
    {"acceptsMouseEvents", touchbar_virtual_acceptsMouseEvents},
    {"image",              touchbar_virtual_asImage},
    {"streaming",          touchbar_virtual_streaming},
    {"level",              touchbar_virtual_level},

    {"__tostring",         userdata_tostring},
    {"__eq",               userdata_eq},
    {"__gc",               userdata_gc},
    {NULL,                 NULL}
} ;

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",          touchbar_virtual_new},

    {NULL,        NULL}
} ;

// Metatable for module, if needed
static const luaL_Reg module_metaLib[] = {
    {"__gc", meta_gc},
    {NULL,   NULL}
} ;

int luaopen_hs_libtouchbar_virtual(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:module_metaLib
                               objectFunctions:userdata_metaLib] ;

    initialDFRStatus = DFRGetStatus() ;

    [skin registerPushNSHelper:pushASMTouchBarWindow         forClass:"ASMTouchBarWindow"] ;
    [skin registerLuaObjectHelper:toASMTouchBarWindowFromLua forClass:"ASMTouchBarWindow"
                                                  withUserdataMapping:USERDATA_TAG] ;

    return 1 ;
}
