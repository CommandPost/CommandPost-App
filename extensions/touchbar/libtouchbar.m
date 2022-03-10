@import Cocoa ;
@import LuaSkin ;

static const char *USERDATA_TAG = "hs.touchbar" ;

// Weakly linking to these function *should* allow loading this file on machines running 10.12.1 or earlier, but I'll need to find one to test
// extern BOOL   DFRSetStatus(int) __attribute__((weak_import)) ;
extern int    DFRGetStatus(void) __attribute__((weak_import)) ;
extern CGSize DFRGetScreenSize(void) __attribute__((weak_import)) ;

static BOOL is_supported() { return NSClassFromString(@"DFRElement") ? YES : NO ; }

/// hs.touchbar.supported([showLink]) -> boolean
/// Function
/// Returns a boolean value indicathing whether or not the Apple Touch Bar is supported on this Macintosh.
///
/// Parameters:
///  * `showLink` - a boolean, default false, specifying whether a dialog prompting the user to download the necessary update is presented if Apple Touch Bar support is not found in the current Operating System.
///
/// Returns:
///  * true if Apple Touch Bar support is found in the current Operating System or false if it is not.
///
/// Notes:
///  * the link in the prompt is https://support.apple.com/kb/dl1897
static int touchbar_supported(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    BOOL showDialog = (lua_gettop(L) == 1) ? (int)lua_toboolean(L, 1) : NO ;
    lua_pushboolean(L, is_supported()) ;
    if (!lua_toboolean(L, -1) && showDialog) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error: could not detect Touch Bar support"];
        [alert setInformativeText:[NSString stringWithFormat:@"We need at least macOS 10.12.1 (Build 16B2657).\n\nYou have: %@.\n", [NSProcessInfo processInfo].operatingSystemVersionString]];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Get macOS Update"];
        NSModalResponse response = [alert runModal];
        if(response == NSAlertSecondButtonReturn) {
            NSURL *appleUpdateURL = [NSURL URLWithString:@"https://support.apple.com/kb/dl1897"] ;
            [[NSWorkspace sharedWorkspace] openURL:appleUpdateURL];
        }
    }
    return 1 ;
}

/// hs.touchbar.exists() -> boolean
/// Function
/// Returns whether or not the touchbar exists on this machine, real *or* virtual.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean value indicating whether or a not the touchbar exists (true) or does not exist (false) on this machine.
///
/// Notes:
///  * Checking the value of this function does not indicate whether or not the machine *can* support the Touch Bar but rather if it is *currently* supporting the Touch Bar; Use [hs.touchbar.supported](#supported) to check whether or not the machine *can* support the Touch Bar.
///
///  * On machines with a physical touchbar (see also [hs.touchbar.physical](#physical)), this function will always return true.
///  * On machines without a physical touchbar, this function will return true if a virtual touchbar has been created with the `hs.touchbar.virtual` submodule or through another third-party application.
static int touchbar_exists(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (DFRGetStatus != NULL) {
        // mimics _DFRAvailable as disassembled from the DFRFoundation with Hopper Disassembler
        lua_pushboolean(L, (DFRGetStatus() > 0) ? YES : NO) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

/// hs.touchbar.physical() -> boolean
/// Function
/// Returns whether or not the machine has a physical touchbar
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean value indicating whether or not the machine has a physical touchbar (true) or does not (false)
///
/// Notes:
///  * To determine if the machine is currently maintaining a touchbar, physical *or* virtual, use [hs.touchbar.exists](#exists).
static int touchbar_hasPhysicalTouchbar(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;
    if (DFRGetStatus != NULL) {
        lua_pushboolean(L, ((DFRGetStatus() & 1) == 1)) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}


/// hs.touchbar.size() -> sizeTable
/// Function
/// Returns the size of the touchbar as a size table
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table containing key-value fields for the height (h) and width (w) of the touchbar
///
/// Notes:
///  * On a machine without a physical touchbar, noth height and width will be 0 if no virtual touchbar is currently active.
///    * You can use this as a way to test if a third party application has created a virtual touchbar as long as you check **before** `hs.touchbar.virtual.new` has been used; once the virtual submodule's `new` function has been invoked, the height and width will match the virtual touchbar that Hammerspoon has created.
static int touchbar_size(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;
    CGSize touchbarSize = CGSizeZero ;
    if (DFRGetScreenSize != NULL) touchbarSize = DFRGetScreenSize() ;

    [skin pushNSSize:NSSizeFromCGSize(touchbarSize)] ;
    return 1 ;
}


// placeholder
static int touchbar_fakeNew(lua_State *L) {
    lua_pushcfunction(L, touchbar_supported) ;
    lua_pushboolean(L, YES) ;
    lua_pcall(L, 1, 1, 0) ;
    lua_pop(L, 1) ; // pedantic, but let's clean up after ourselves since we're ignoring this.
    lua_pushnil(L) ;
    return 1 ;
}

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"supported", touchbar_supported},
    {"exists",    touchbar_exists},
    {"physical",  touchbar_hasPhysicalTouchbar},
    {"size",      touchbar_size},

    {"_fakeNew",  touchbar_fakeNew},

    {NULL,        NULL}
};

int luaopen_hs_libtouchbar(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin registerLibrary:USERDATA_TAG functions:moduleLib metaFunctions:nil] ;

    return 1;
}
