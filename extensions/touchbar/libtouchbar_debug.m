@import Cocoa ;
@import LuaSkin ;
@import Accelerate ;
@import QuartzCore ;

#import "TouchBar.h"

static const char *USERDATA_TAG = "hs.touchbar.debug" ;
static LSRefTable refTable = LUA_NOREF;

#pragma mark - Support Functions and Classes

#pragma mark - Module Functions

static int debug_dfrStatus(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_gettop(L) > 0) {
        DFRSetStatus((int)lua_tointeger(L, 1)) ;
    }
    lua_pushinteger(L, DFRGetStatus()) ;
    return 1 ;
}

static int debug_touchbarSize(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;
    CGSize touchbarSize = DFRGetScreenSize() ;
    [skin pushNSSize:NSSizeFromCGSize(touchbarSize)] ;
    return 1 ;
}

static int debug_dfrCopyAttributes(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;

    NSDictionary *attributes = (__bridge_transfer NSDictionary *)DFRCopyAttributes() ;
    [skin pushNSObject:attributes] ;
    return 1 ;
}

static int debug_dfrElementGetScaleFactor(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;
    lua_pushnumber(L, DFRElementGetScaleFactor()) ;
    return 1 ;
}


#pragma mark - Hammerspoon/Lua Infrastructure

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"dfrStatus",   debug_dfrStatus},
    {"size",        debug_touchbarSize},
    {"attributes",  debug_dfrCopyAttributes},
    {"scaleFactor", debug_dfrElementGetScaleFactor},

    {NULL,           NULL}
};

int luaopen_hs_libtouchbar_debug(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibrary:USERDATA_TAG functions:moduleLib metaFunctions:nil] ;

    return 1;
}
