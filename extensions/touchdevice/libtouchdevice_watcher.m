/// === hs.touchdevice.watcher ===
///
/// This module allows you to watch for the attaching and detaching of Apple Multitouch devices like the Magic Trackpad and the Force Touch Trackpad.
///
/// On a MacBook Pro, mid 2014, this module does not detect the presence of the built in pre-force touch trackpad, even when passing `true` to [hs.touchdevice.watcher:start](#start), as it uses a different IOService identifier than the external devices I have available to me for testing. I do not know if newer laptops will have this same limitation.

@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs.touchdevice.watcher" ;
static LSRefTable refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static void deviceAddedCallback(void *refCon, io_iterator_t iterator) ;
static void deviceChangeCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) ;

@interface ASMTouchDeviceWatcher : NSObject
@property            int                   selfRefCount ;
@property            int                   callbackRef ;
@property (readonly) BOOL                  running ;
@end

@interface ASMTouchDeviceDevice : NSObject
@property (weak) ASMTouchDeviceWatcher *owner ;
@property        NSNumber              *multitouchID ;
@property        io_object_t           notification ;
@end

@implementation ASMTouchDeviceDevice
-(instancetype)initWithOwner:(ASMTouchDeviceWatcher *)owner forID:(NSNumber *)mtID {
    self = [super init] ;
    if (self) {
        _owner        = owner ;
        _multitouchID = mtID ;
    }
    return self ;
}

-(io_object_t *)notificationPointer {
    return &_notification ;
}
@end

@implementation ASMTouchDeviceWatcher {
    BOOL                  _firstRun ;
    IONotificationPortRef _notificationPort ;
    io_iterator_t         _iterator ;
    CFRunLoopSourceRef    _runLoopSource ;
    NSMutableArray        *_discoveredDevices ;
}

- (instancetype)init {
    self = [super init] ;
    if (self) {
        _selfRefCount     = 0 ;
        _callbackRef      = LUA_NOREF ;
        _running          = NO ;

        _notificationPort  = IONotificationPortCreate(kIOMasterPortDefault) ;
        _runLoopSource     = IONotificationPortGetRunLoopSource(_notificationPort) ;
        _firstRun          = NO ;
        _discoveredDevices = [NSMutableArray array] ;
    }
    return self ;
}

-(void)dealloc {
    if (_selfRefCount == 0) {
        [self stop] ;
        IONotificationPortDestroy(_notificationPort) ;
        _discoveredDevices = nil ;
    }
}

-(void)startWithFirstRun:(BOOL)includeFirstRun {
    if (!_running) {
        _running = YES ;
        CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode) ;
        kern_return_t err = IOServiceAddMatchingNotification(_notificationPort,
                                                             kIOFirstMatchNotification,
                                                             IOServiceMatching("AppleMultitouchDevice"),
                                                             deviceAddedCallback,
                                                             (__bridge void *)self,
                                                             &_iterator) ;

        if (err == KERN_SUCCESS) {
            // gotta iterate through to arm iterator for future notifications; plus
            // this allows us to start up removal watchers on the existing devices
            _firstRun = !includeFirstRun ;
            deviceAddedCallback((__bridge void *)self, _iterator) ;
            _firstRun = NO ;
        } else {
            [LuaSkin logError:[NSString stringWithFormat:@"%s:start - unable to create notification watcher (error 0x%0x)", USERDATA_TAG, err]] ;
            _running = NO ;
        }
    }
}

-(void)stop {
    if (_running) {
        _running = NO ;
        IOObjectRelease(_iterator) ;
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode) ;
        [_discoveredDevices removeAllObjects] ;
    }
}

-(void)addDevice:(io_service_t)service {
    CFMutableDictionaryRef deviceData ;
    IORegistryEntryCreateCFProperties(service, &deviceData, kCFAllocatorDefault, kNilOptions) ;
    CFNumberRef multitouchID = CFDictionaryGetValue(deviceData, CFSTR("Multitouch ID")) ;
    // set up notifier for when device disappears

    ASMTouchDeviceDevice *deviceNotifier = [[ASMTouchDeviceDevice alloc] initWithOwner:self forID:(__bridge NSNumber *)multitouchID] ;
    kern_return_t err = IOServiceAddInterestNotification(_notificationPort,
                                                         service,
                                                         kIOGeneralInterest,
                                                         deviceChangeCallback,
                                                         (__bridge void *)deviceNotifier,
                                                         deviceNotifier.notificationPointer);

    if (err == KERN_SUCCESS) {
        [_discoveredDevices addObject:deviceNotifier] ;
    } else {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:addDevice - unable to create change watcher to detect removal (error 0x%0x)", USERDATA_TAG, err]] ;
        deviceNotifier.owner = nil ;
    }

    if (!_firstRun && _callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin sharedWithState:NULL] ;
        lua_State *L = skin.L ;
        _lua_stackguard_entry(L) ;

        [skin pushLuaRef:refTable ref:_callbackRef] ;
        lua_pushstring(L, "add") ;
        [skin pushNSObject:deviceNotifier.multitouchID] ;
        [skin protectedCallAndError:[NSString stringWithFormat:@"%s:addDevice callback error", USERDATA_TAG]
                              nargs:2
                           nresults:0] ;

        _lua_stackguard_exit(L) ;
    }
    CFRelease(deviceData) ;
}

-(void)removeDevice:(ASMTouchDeviceDevice *)deviceNotifier {
    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin sharedWithState:NULL] ;
        lua_State *L = skin.L ;
        _lua_stackguard_entry(L) ;

        [skin pushLuaRef:refTable ref:_callbackRef] ;
        lua_pushstring(L, "remove") ;
        [skin pushNSObject:deviceNotifier.multitouchID] ;
        [skin protectedCallAndError:[NSString stringWithFormat:@"%s:removeDevice callback error", USERDATA_TAG]
                              nargs:2
                           nresults:0] ;

        _lua_stackguard_exit(L) ;
    }
    [_discoveredDevices removeObject:deviceNotifier] ;
}
@end

static void deviceChangeCallback(void *refCon, __unused io_service_t service, natural_t messageType, __unused void *messageArgument) {
    ASMTouchDeviceDevice *deviceNotifier = (__bridge ASMTouchDeviceDevice *)refCon ;
    if (messageType == kIOMessageServiceIsTerminated) {
        // our hold on it *is* weak, so best to be certain
        ASMTouchDeviceWatcher *owner = deviceNotifier.owner ;
        if (owner != nil) [owner removeDevice:deviceNotifier] ;
        IOObjectRelease(deviceNotifier.notification) ;
    }
}

static void deviceAddedCallback(void *refCon, io_iterator_t iterator) {
    ASMTouchDeviceWatcher *self = (__bridge ASMTouchDeviceWatcher *)refCon ;
    io_service_t item ;
    while ((item = IOIteratorNext(iterator))) {
        [self addDevice:item] ;
        IOObjectRelease(item) ;
    }
}

#pragma mark - Module Functions

/// hs.touchdevice.watcher.new([fn]) -> watcherObject | nil
/// Constructor
/// Creates a new Multitouch device watcher
///
/// Parameters:
///  * `fn` - an optional function which will be invoked when a multitouch trackpad is added or removed  from the system. See also [hs.touchdevice.watcher:callback](#callback).
///
/// Returns:
///  * the watcherObject or nil if there was an error creating the watcher.
///
/// Notes:
///  * This constructor creates the watcher, but does not start it. See [hs.touchdevice.watcher:start](#start).
///  * For details about the callback function, see [hs.touchdevice.watcher:callback](#callback).
static int td_watcher_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TFUNCTION | LS_TOPTIONAL, LS_TBREAK] ;

    ASMTouchDeviceWatcher *watcher = [[ASMTouchDeviceWatcher alloc] init] ;
    if (watcher) {
        if (lua_gettop(L) == 1) {
            lua_pushvalue(L, 1) ;
            watcher.callbackRef = [skin luaRef:refTable] ;
        }
        [skin pushNSObject:watcher] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs.touchdevice.watcher:callback([fn]) -> watcherObject | function | nil
/// Method
/// Get or change the callback function assigned to the watcher.
///
/// Parameters:
///  * `fn` - an optional function or explicit `nil` which will replace the existing callback if provided. An explicit `nil` will remove the existing callback, if any, without replacing it.
///
/// Returns:
///  * if an argument is provided, returns the watcherObject; otherwise returns the callback function, if defined, or nil if no callback function is currently assigned.
///
/// Notes:
///  * The callback function should expect 2 arguments and return none:
///    * `state`   - a string specifying whether a new device was added ("add") or an existing device was removed ("remove").
///    * `mtID`    - an integer specifying the multitouch ID for the device which has been added or removed. See the documentation for `hs.touchdevice` for how to use this ID.
static int td_watcher_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMTouchDeviceWatcher *watcher = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if (watcher.callbackRef == LUA_NOREF) {
            lua_pushnil(L) ;
        } else {
            [skin pushLuaRef:refTable ref:watcher.callbackRef] ;
        }
    } else {
        watcher.callbackRef = [skin luaUnref:refTable ref:watcher.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            watcher.callbackRef = [skin luaRef:refTable] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs.touchdevice.watcher:start([includeExisting]) -> watcherObject
/// Method
/// Starts the watcher so that multitouch devices being added or removed will trigger a callback.
///
/// Parameters:
///  * `includeExisting` - an optional boolean, default false, indicating whether or not existing devices detected when the watcher starts should trigger immediate "add" callbacks or not. Existing devices will still trigger "remove" callbacks when they are removed, even if this argument is false or unset.
///
/// Returns:
///  * the watcherObject
///
/// Notes:
///  * in initial testing, the built in pre forcetouch trackpad on a 2014 MacBook Pro is not detected by this watcher, even when this method is passed `true`. It is uncertain at this time if this will also be the case for more modern machines or not. However since the built in device cannot be removed, the impact is minimal, as built in devices are still detected by `hs.touchdevice.devices()`.
static int td_watcher_start(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDeviceWatcher *watcher = [skin toNSObjectAtIndex:1] ;
    BOOL includeFirstRun = lua_gettop(L) > 1 ? (BOOL)(lua_toboolean(L, 2)) : NO ;
    [watcher startWithFirstRun:includeFirstRun] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchdevice.watcher:stop() -> watcherObject
/// Method
/// Stops the watcher so that callbacks for multitouch devices being added or removed are no longer triggered.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the watcherObject
static int td_watcher_stop(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDeviceWatcher *watcher = [skin toNSObjectAtIndex:1] ;
    [watcher stop] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs.touchdevice.watcher:isRunning() -> boolean
/// Method
/// Returns whether or not the watcher is currently active.
///
/// Parameters:
///  * None
///
/// Returns:
///  * true of the watcher is running or false if it is not.
static int td_watcher_isRunning(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDeviceWatcher *watcher = [skin toNSObjectAtIndex:1] ;
    lua_pushboolean(L, watcher.running) ;
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushASMTouchDeviceWatcher(lua_State *L, id obj) {
    ASMTouchDeviceWatcher *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(ASMTouchDeviceWatcher *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

static id toASMTouchDeviceWatcherFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    ASMTouchDeviceWatcher *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge ASMTouchDeviceWatcher, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
//     ASMTouchDeviceWatcher *obj = [skin luaObjectAtIndex:1 toClass:"ASMTouchDeviceWatcher"] ;
//     NSString *title = ... ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: (%p)", USERDATA_TAG, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    ASMTouchDeviceWatcher *obj = get_objectFromUserdata(__bridge_transfer ASMTouchDeviceWatcher, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj. selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin sharedWithState:L] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            [obj stop] ;
            obj = nil ;
        }
    }
    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"start",      td_watcher_start},
    {"stop",       td_watcher_stop},
    {"isRunning",  td_watcher_isRunning},
    {"callback",   td_watcher_callback},

    {"__tostring", userdata_tostring},
    {"__gc",       userdata_gc},
    {NULL,         NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", td_watcher_new},

    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs_libtouchdevice_watcher(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushASMTouchDeviceWatcher         forClass:"ASMTouchDeviceWatcher"];
    [skin registerLuaObjectHelper:toASMTouchDeviceWatcherFromLua forClass:"ASMTouchDeviceWatcher"
                                                      withUserdataMapping:USERDATA_TAG];

    return 1;
}
