@import Cocoa ;
@import LuaSkin ;

#import "text.h"

/// === hs.text.regex ===
///
/// Provides proper regular expression support for lua strings and `hs.text.utf16` objects.
///
/// This submodule provides more complete and proper regular expression functionality as provided by the macOS Objective-C runtime.
///
/// A full breakdown of the regular expression syntax is beynd the scope of this document, but a formal description of the syntax supported can be found at http://userguide.icu-project.org/strings/regexp.
///
/// Note that the Lua Pattern Matching supported by `string.match`, `string.gmatch`, `string.find`, and `string.gsub` is syntatically different from regular expression syntax; however, regular expressions provide much more flexibility and are significantly more portable across other programming languages and platforms.
///
/// Wrappers for the `string` library functions identified above are provided (using regular expression syntax), and can be used with both lua strings and `hs.text.utf16` objects, but you are not limited to their use.
///
/// The backslash (`\`) is the primary metacharacter sequence identifier for regular expressions; because Lua uses this for its own escape sequences, it is recommended that you use Lua's block quotes when defining patterns for clarity (e.g. `[[\w+]]` instead of `"\\w+"`). Examples provided within this submodule's documentation will primarily use this block quote syntax.
static int refTable = LUA_NOREF;

#pragma mark - Support Functions and Classes

@implementation HSRegularExpression

- (instancetype)initWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options {
    NSError *error = nil ;
    self = [super initWithPattern:pattern options:options error:&error] ;
    if (error) {
        self = nil ; // probably will be anyways, but let us be explicit
        [LuaSkin logError:[NSString stringWithFormat:@"%s - initWithPattern:%@ options:%lu error:%@", REGEX_UD_TAG, pattern, options, error.localizedDescription]] ;
    }
    if (self) {
        _selfRefCount = 0 ;
    }
    return self ;
}

@end

#pragma mark - Module Functions

// documented in  init.lua
static int regex_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    NSString                   *expression = [skin toNSObjectAtIndex:1] ;
    NSRegularExpressionOptions options     = (lua_gettop(L) > 1) ? (NSRegularExpressionOptions)(lua_tointeger(L, 2)) : 0 ;

    HSRegularExpression *regex = [[HSRegularExpression alloc] initWithPattern:expression options:options] ;
    if (regex) {
        [skin pushNSObject:regex] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs.text.regex.escapedTemplate(template) -> string
/// Function
/// Returns a lua string by adding backslash escapes as necessary to protect any characters that would match as template pattern metacharacters
///
/// Parameters:
///  * `template` -- a lua string specifying the template string in which to escape metacharacters.
///
/// Returns:
///  * a lua string
///
/// Notes:
///  * this would typically be used when crafting a larger template string for use with substitution methods and want to make sure that this sections is replaced *exactly* and not expanded based on expression captures.
///  * e.g. `hs.text.regex.escapedTemplate("$1")` returns `"\$1"`
static int regex_escapedTemplateForString(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING, LS_TBREAK] ;
    NSString *templateString = [skin toNSObjectAtIndex:1]  ;

    [skin pushNSObject:[NSRegularExpression escapedTemplateForString:templateString]] ;
    return 1 ;
}

/// hs.text.regex.escapedPattern(pattern) -> string
/// Function
/// Returns a lua string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters
///
/// Parameters:
///  * `pattern` -- a lua string specifying the pattern string in which to escape metacharacters.
///
/// Returns:
///  * a lua string
///
/// Notes:
///  * this would typically be used when crafting a larger pattern string for use with [hs.text.regex.new](#new) and want to make sure that this sections is matched *exactly* and not treated as regular expression metacharacters.
///  * e.g. `hs.text.regex.escapedPattern("(N/A)")` returns `"\(N\/A\)"`
static int regex_escapedPatternForString(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING, LS_TBREAK] ;
    NSString *patternString = [skin toNSObjectAtIndex:1]  ;

    [skin pushNSObject:[NSRegularExpression escapedPatternForString:patternString]] ;
    return 1 ;
}


#pragma mark - Module Methods

/// hs.text.regex:pattern() -> string
/// Method
/// Returns the string representation of the regular expression specified when this regular expression object was created
///
/// Parameters:
///  * None
///
/// Returns:
///  * a lua string
static int regex_pattern(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG, LS_TBREAK] ;
    HSRegularExpression *regex = [skin toNSObjectAtIndex:1] ;

    [skin pushNSObject:regex.pattern] ;
    return 1 ;
}

/// hs.text.regex:options() -> integer
/// Method
/// Returns the options specified when this regular expression object was created
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer containing logically OR'ed values from the [hs.text.regex.expressionOptions](#expressionOptions) constant specifying the options that were specified when this object was created.
static int regex_options(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG, LS_TBREAK] ;
    HSRegularExpression *regex = [skin toNSObjectAtIndex:1] ;

    lua_pushinteger(L, (lua_Integer)regex.options) ;
    return 1 ;
}

/// hs.text.regex:captureCount() -> integer
/// Method
/// Returns the number of capture groups specified by the regular expression defining this object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer specifying the number of capture groups defined by the regular expression object.
static int regex_captureCount(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG, LS_TBREAK] ;
    HSRegularExpression *regex = [skin toNSObjectAtIndex:1] ;

    lua_pushinteger(L, (lua_Integer)regex.numberOfCaptureGroups) ;
    return 1 ;
}

/// hs.text.regex:firstMatch(text, [i], [j], [options]) -> table | nil
/// Method
/// Returns the first match of the regular expression within the specified range of the text.
///
/// Parameters:
///  * `text`     - the text to apply the regular expression to, privded as a lua string or `hs.text.utf16` object.
///  * `i`        - an optional integer, default 1, specifying the starting index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
///  * `j`        - an optional integer, default -1, specifying the ending index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text. If you wish to specify this parameter, you *must* provide a value for `i`.
///  * `options` - an optional integer, default 0. The integer should a combination of 1 or more of the numeric values in the [hs.text.regex.matchOptions](#matchOptions) constant logically OR'ed together (e.g. `hs.text.regex.matchOptions.withoutAnchoringBounds | hs.text.regex.matchOptions.withTransparentBounds`). If you wish to specify this parameter, you *must* provide a value for both `i` and `j`.
///
/// Returns:
///  * If the pattern is not found within the specified range of the text, returns nil.
///  * If the pattern is found and no captures were specified in the pattern, then the table returned will have the starting index of the matched pattern within the text as its first element and the ending index as its second element.
///  * If the pattern is found and specified captures, then the table returned will contain tables for each capture, specifying the starting and ending indicies of each capture in the order they were specified within the pattern. A table at index 0 will contain the starting and ending indicies of the entire match. If a given capture is empty, its position within the returned table will be `nil`.
///
/// Notes:
///  * if `text` is a lua string:
///    * all indicies (parameters and returned values) are specified in terms of byte positions within the string.
///    * if `i` or `j` fall within the middle of a composite UTF8 byte sequence, they will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
///  * if `text` is an `hs.text.utf16` object:
///    * all indicies (parameters and callback values) are specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and capture indicies if this might be an issue for your purposes.
static int regex_firstMatch(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG,
                    LS_TANY, // checked below
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    HSRegularExpression *regex       = [skin toNSObjectAtIndex:1] ;
    NSString            *textUTF16   = nil ;
    const char          *textUTF8    = NULL ;
    lua_Integer         length       = 0 ;

    BOOL                textIsUD     = (lua_type(L, 2) == LUA_TUSERDATA) ;

    if (textIsUD) {
        [skin checkArgs:LS_TANY, LS_TUSERDATA, UTF16_UD_TAG, LS_TBREAK | LS_TVARARG] ;
        HSTextUTF16Object *utf16Object = [skin toNSObjectAtIndex:2] ;
        textUTF16 = utf16Object.utf16string ;
        length    = (lua_Integer)textUTF16.length ;
    } else {
        [skin checkArgs:LS_TANY, LS_TSTRING, LS_TBREAK | LS_TVARARG] ;
        size_t l = 0 ;
        textUTF8 = lua_tolstring(L, 2, &l) ;
        length = (lua_Integer)l ;
    }

    lua_Integer i = (lua_gettop(L) > 2) ? lua_tointeger(L, 3) :  1 ;
    lua_Integer j = (lua_gettop(L) > 3) ? lua_tointeger(L, 4) : -1 ;

    NSMatchingOptions options = (lua_gettop(L) > 4) ? (NSMatchingOptions)(lua_tointeger(L, 5)) : 0 ;

    // adjust indicies per lua standards
    if (i < 0) i = length + 1 + i ; // negative indicies are from string end
    if (j < 0) j = length + 1 + j ; // negative indicies are from string end

    // match behavior of utf8 functions that take indicies
    if ((i < 1) || (i > length)) return luaL_error(L, "starting index out of range") ;
    if ((j < 1) || (j > length)) return luaL_error(L, "ending index out of range") ;

    NSString *stringToEnumerate = textUTF16 ;
    if (!textIsUD) {
        // it's stupid that I either have to add 3 lines of compiler pragmas or use (void *)(uintptr_t) to cast between
        // (const char *) and (void *) -- ok, I get the irony(?) of taking four lines to explain it here, but this is
        // in an effort to explain what's happening so hopefully I'll remember it or can search for it next time...
        // see comments from https://stackoverflow.com/a/44356147 and https://stackoverflow.com/a/1846648
        NSData *tmpDataBlock = [NSData dataWithBytesNoCopy:(void *)(uintptr_t)textUTF8 length:(NSUInteger)length freeWhenDone:NO] ;
        stringToEnumerate    = [[NSString alloc] initWithData:tmpDataBlock encoding:NSUTF8StringEncoding] ;
    }

    // build map of NSString indicies to source indicies; a small waste for UTF16 objects, but necessary for lua's UTF8 strings
    NSUInteger *indiciesMap = malloc(sizeof(NSUInteger) * stringToEnumerate.length) ;
    BOOL i_needsAdjusting   = !textIsUD ;
    BOOL j_needsAdjusting   = !textIsUD ;

    for (NSUInteger n = 0 ; n < stringToEnumerate.length ; n++) {
        if (textIsUD || (n == 0)) {
            indiciesMap[n] = n ;
        } else {
            // UTF8 size:
            //     1 byte  for U+0000  - U+007F
            //     2 bytes for U+0080  - U+07FF
            //     3 bytes for U+0800  - U+FFFF   (except for D800-DFFF, which UTF16 uses for surrogate pairs)
            //     4 bytes for U+10000 - U+10FFFF (i.e. the surrogate pairs, so we add 2 to idx for each member, resulting in 4

            NSUInteger idx = indiciesMap[n - 1] + 1 ; // assume one byte
            unichar  ch1 = [stringToEnumerate characterAtIndex:(n - 1)] ;
            if (CFStringIsSurrogateHighCharacter(ch1) || CFStringIsSurrogateLowCharacter(ch1)) {
                idx++ ; // make it two bytes for a surrogate member
            } else {
                if (ch1 > 0x007f) idx++ ; // ok, it's at least in the two byte range
                if (ch1 > 0x07ff) idx++ ; // nope, it's in the three byte range
            }
            indiciesMap[n] = idx ;
        }

        // if i or j point to middle of multi-byte UTF8 character, this actually skips to the next good character...
        // annoying, but I don't' think I can fix it short of implementing completely sepparate code for UTF8 and UTF16
        // since macOS does everything internally as UTF16... wait and see how big of an issue this really is...
        if (i_needsAdjusting && (i <= (lua_Integer)(indiciesMap[n] + 1))) {
            i_needsAdjusting = NO ;
            i = (lua_Integer)n + 1 ;
        }

        if (j_needsAdjusting && (j <= (lua_Integer)(indiciesMap[n] + 1))) {
            j_needsAdjusting = NO ;
            j = (lua_Integer)n + 1 ;
        }
    }

    NSTextCheckingResult *result = [regex firstMatchInString:stringToEnumerate
                                                     options:options
                                                       range:NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1)))] ;

    if (result) {
        lua_newtable(L) ;
        if (result.numberOfRanges == 1) {
            lua_pushinteger(L, (lua_Integer)(indiciesMap[result.range.location] + 1)) ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
            lua_pushinteger(L, (lua_Integer)(indiciesMap[result.range.location + result.range.length - 1] + 1)) ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        } else {
            for (NSUInteger idx = 0 ; idx < result.numberOfRanges ; idx++) {
                NSRange range = [result rangeAtIndex:idx] ;
                if (range.location != NSNotFound) {
                    lua_newtable(L) ;
                    lua_pushinteger(L, (lua_Integer)(indiciesMap[range.location] + 1)) ;
                    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
                    lua_pushinteger(L, (lua_Integer)(indiciesMap[range.location + range.length - 1] + 1)) ;
                    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;

                    lua_rawseti(L, -2, (lua_Integer)idx) ;
                }
            }
        }
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs.text.regex:gsubIn(text, template, [n]) -> updatedText, count
/// Method
/// Return a gopy of the text where occurrences of the regex pattern have been replaced; global substitution for use like `string.gsub`.
///
/// Parameters:
///  * `text`        - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
///  * `template`    - a lua string, `hs.text.utf16` object, table, or function which specifies replacement(s) for pattern matches.
///    * if `template` is a string or `hs.text.utf16` object, then its value is used for replacement.
///    * if `template` is a table, the table is queried for every match using the first capture (if captures are specified) or the entire match (if no captures are specified). Keys in the table must be lua strings or `hs.text.utf16` objects, and values must be lua strings, numbers, or `hs.text.utf16` objects. If no key matches the capture, no replacement of the match occurs.
///    * if `template` is a function, the function will be called with all of the captured substrings passed in as lua strings or `hs.text.utf16` objects (based upon the type for `text`) in order (or the entire match, if no captures are specified). The return value is used as the repacement of the match and must be `nil`, a lua string, a number, or a `hs.text.utf16` object. If the return value is `nil`, no replacement of the match occurs.
///  * `n`           - an optional integer specifying the maximum number of replacements to perform. If this is not specified, all matches in the object will be replaced.
///
/// Returns:
///  * a new lua string or `hs.text.utf16` object (based upon the type for `text`) with the substitutions specified, followed by an integer indicating the number of substitutions that occurred.
///
/// Notes:
///  * If `template` is a lua string or `hs.text.utf16` object, any sequence in the replacement of the form `$n` where `n` is an integer >= 0 will be replaced by the `n`th capture from the pattern (`$0` specifies the entire match). A `$` not followed by a number is treated as a literal `$`. To specify a literal `$` followed by a numeric digit, escape the dollar sign (e.g. `\$1`).
///    * If you are concerned about possible meta-characters in the template that you wish to be treated literally, see [hs.text.regex.escapedTemplate](#escapedTemplate).
///
///  * The following examples are from the Lua documentation for `string.gsub` modified with the proper syntax:
///
///      ~~~
///      x = hs.text.regex.new("(\\w+)"):gsubIn("hello world", "$1 $1")
///      -- x will equal "hello hello world world"
///
///      -- note that if we use Lua's block quotes (e.g. `[[` and `]]`), then we don't have to escape the backslash:
///
///      x = hs.text.regex.new([[\w+]]):gsubIn("hello world", "$0 $0", 1)
///      -- x will equal "hello hello world"
///
///      x = hs.text.regex.new([[(\w+)\s*(\w+)]]):gsubIn("hello world from Lua", "$2 $1")
///      -- x will equal "world hello Lua from"
///
///      x = hs.text.regex.new([[\$(\w+)]]):gsubIn("home = $HOME, user = $USER", function(a) return os.getenv(tostring(a)) end)
///      -- x will equal "home = /Users/username, user = username"
///
///      x = hs.text.regex.new([[\$(.+)\$]]):gsubIn("4+5 = $return 4+5$", function (s) return load(tostring(s))() end)
///      -- x will equal "4+5 = 9"
///
///      local t = {name="lua", version="5.3"}
///      x = hs.text.regex.new([[\$(\w+)]]):gsubIn("$name-$version.tar.gz", t)
///      -- x will equal "lua-5.3.tar.gz"
///      ~~~
static int regex_gsubIn(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG, LS_TANY, LS_TANY, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSRegularExpression *regex = [skin toNSObjectAtIndex:1] ;
    NSString            *text  = nil ;

    BOOL                textIsUD = (lua_type(L, 2) == LUA_TUSERDATA) ;

    if (textIsUD) {
        [skin checkArgs:LS_TANY, LS_TUSERDATA, UTF16_UD_TAG, LS_TBREAK | LS_TVARARG] ;
        HSTextUTF16Object *utf16Object = [skin toNSObjectAtIndex:2] ;
        text = utf16Object.utf16string ;
    } else {
        [skin checkArgs:LS_TANY, LS_TSTRING, LS_TBREAK | LS_TVARARG] ;
        text = [skin toNSObjectAtIndex:2] ;
    }

    // prepare placeholders for the possible values of argument 3
    NSString *replString = (lua_type(L, 3) == LUA_TSTRING) ? [skin toNSObjectAtIndex:3] : nil ;
    if (lua_type(L, 3) == LUA_TUSERDATA) {
        [skin checkArgs:LS_TANY, LS_TANY, LS_TUSERDATA, UTF16_UD_TAG, LS_TBREAK | LS_TVARARG] ;
        HSTextUTF16Object *replObject = [skin toNSObjectAtIndex:3] ;
        replString = replObject.utf16string ;
    } else {
        [skin checkArgs:LS_TANY, LS_TANY, LS_TSTRING | LS_TTABLE | LS_TFUNCTION, LS_TBREAK | LS_TVARARG] ;
    }

    NSDictionary *replDictionary = (lua_type(L, 3) == LUA_TTABLE)  ? [skin toNSObjectAtIndex:3] : nil ;
    if (replDictionary) {
        // if they pass in an array like table, we silently ignore it since the keys have to be strings
        if ([replDictionary isKindOfClass:[NSArray class]]) {
            replDictionary = [NSDictionary dictionary] ;
        } else {
            NSMutableDictionary *realReplDictionary = [NSMutableDictionary dictionaryWithCapacity:replDictionary.count] ;
            __block NSString *errorMessage = nil ;
            [replDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                NSString *newKey   = key ;
                NSString *newValue = value ;
                if ([key isKindOfClass:[HSTextUTF16Object class]]) {
                    newKey = ((HSTextUTF16Object *)key).utf16string ;
                } else if (![key isKindOfClass:[NSString class]]) {
                    errorMessage = @"expected string or hs.text.utf16 object for replacement key in table" ;
                    *stop = true ;
                    return ;
                }
                if ([value isKindOfClass:[HSTextUTF16Object class]]) {
                    newValue = ((HSTextUTF16Object *)value).utf16string ;
                } else if ([value isKindOfClass:[NSNumber class]]) {
                    newValue = ((NSNumber *)value).stringValue ;
                } else if (![value isKindOfClass:[NSString class]]) {
                    errorMessage = @"expected string, number, or hs.text.utf16 object for replacement value in table" ;
                    *stop = true ;
                    return ;
                }
                realReplDictionary[newKey] = newValue ;
            }] ;
            if (errorMessage) return luaL_argerror(L, 3, errorMessage.UTF8String) ;

            replDictionary = [realReplDictionary copy] ;
        }
    }

    int replFnRef = LUA_NOREF ;
    if (lua_type(L, 3) == LUA_TFUNCTION) {
        lua_pushvalue(L, 3) ;
        replFnRef = [skin luaRef:refTable] ;
    }

    lua_Integer maxSubstitutions = (lua_gettop(L) > 3) ? lua_tointeger(L, 4) : ((lua_Integer)text.length + 1) ;

    lua_Integer changeCount = 0 ;

    // inspired by https://stackoverflow.com/a/23827451
    NSMutableString* mutableText = [text mutableCopy] ;
    NSInteger offset = 0 ; // keeps track of range changes in the string due to replacements.
    for (NSTextCheckingResult* result in [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)]) {
        if (changeCount >= maxSubstitutions) break ;

        NSRange resultRange = [result range] ;
        // update based on cumulative offset
        resultRange.location = (NSUInteger)((NSInteger)resultRange.location + offset) ;

        NSMutableArray *captures = [NSMutableArray arrayWithCapacity:result.numberOfRanges] ;
        for (NSUInteger i = 0 ; i < result.numberOfRanges ; i++) {
            NSRange captureRange = [result rangeAtIndex:i] ;
            if (captureRange.location == NSNotFound) {
                [captures addObject:@""] ;
            } else {
                // update based on cumulative offset
                captureRange.location = (NSUInteger)((NSInteger)captureRange.location + offset) ;
                [captures addObject:[mutableText substringWithRange:captureRange]] ;
            }
        }

        // here's where the magic happens
        NSString *replacement = nil ;
        if (replString) {
            replacement = [regex replacementStringForResult:result inString:mutableText offset:offset template:replString] ;
        } else if (replDictionary) {
            replacement = [replDictionary objectForKey:(captures.count > 1) ? captures[1] : captures[0]] ;
            if (!replacement) replacement = captures[0] ;
        } else if (replFnRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:replFnRef] ;
            int argCount = (int)captures.count - 1 ;
            if (argCount == 0) {
                if (textIsUD) {
                    HSTextUTF16Object *newObject = [[HSTextUTF16Object alloc] initWithString:captures[0]] ;
                    [skin pushNSObject:newObject] ;
                } else {
                    [skin pushNSObject:captures[0]] ;
                }
                argCount = 1 ;
            } else {
                for (NSUInteger i = 1 ; i < captures.count ; i++) {
                    if (textIsUD) {
                        HSTextUTF16Object *newObject = [[HSTextUTF16Object alloc] initWithString:captures[i]] ;
                        [skin pushNSObject:newObject] ;
                    } else {
                        [skin pushNSObject:captures[i]] ;
                    }
                }
            }
            if (![skin protectedCallAndTraceback:argCount nresults:1]) {
                return luaL_error(L, lua_tostring(L, -1)) ;
            } else {
                switch(lua_type(L, -1)) {
                    case LUA_TNIL:
                        replacement = captures[0] ;
                        break ;
                    case LUA_TSTRING:
                        {
                            NSData *input = [skin toNSObjectAtIndex:-1 withOptions:LS_NSLuaStringAsDataOnly] ;
                            replacement = [[NSString alloc] initWithData:input encoding:NSUTF8StringEncoding] ;
                        }
                        break ;
                    case LUA_TNUMBER:
                        replacement = [NSString stringWithCString:lua_tostring(L, -1) encoding:NSUTF8StringEncoding] ;
                        break ;
                    case LUA_TUSERDATA:
                        if (luaL_testudata(L, -1, UTF16_UD_TAG)) {
                            HSTextUTF16Object *newObject = [skin toNSObjectAtIndex:-1] ;
                            replacement = newObject.utf16string ;
                            break ;
                        }
                    default:
                        return luaL_error(L, "invalid replacement value (a %s)", lua_typename(L, -1)) ;
                }
            }
            lua_pop(L, 1) ;
        }

        // make the replacement
        [mutableText replaceCharactersInRange:resultRange withString:replacement] ;

        // update the offset based on the replacement
        offset += ((NSInteger)replacement.length - (NSInteger)resultRange.length) ;

        changeCount++ ;
    }

    if (replFnRef != LUA_NOREF) {
        replFnRef = [skin luaUnref:refTable ref:replFnRef] ;
    }
    if (textIsUD) {
        HSTextUTF16Object *newObject = [[HSTextUTF16Object alloc] initWithString:mutableText] ;
        [skin pushNSObject:newObject] ;
    } else {
        [skin pushNSObject:mutableText] ;
    }
    lua_pushinteger(L, changeCount) ;
    return 2 ;
}

// /// hs.text.regex:matchWithCallback(text, callback, [options], [i], [j]) -> regexObject
// /// Method
// /// Apply the regular expression to the provided text, invoking the callback for each match.
// ///
// /// Parameters:
// ///  * `text`     - the text to apply the regular expression to, privded as a lua string or `hs.text.utf16` object.
// ///  * `callback` - the function which will be invoked for each match. The callback should expect 1 or more parameters and may return 1, described as follows:
// ///    *
// ///  * `i`        - an optional integer, default 1, specifying the starting index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
// ///  * `j`        - an optional integer, default -1, specifying the ending index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
// ///  * `options` - an optional integer, default 0. The integer should a combination of 1 or more of the numeric values in the [hs.text.regex.matchOptions](#matchOptions) constant logically OR'ed together (e.g. `hs.text.regex.matchOptions.withoutAnchoringBounds | hs.text.regex.matchOptions.withTransparentBounds`). If you wish to specify this parameter, you *must* provide a value for both `i` and `j`.
// ///
// /// Returns:
// ///  * the regexObject
// ///
// /// Notes:
// ///  * if `text` is a lua string:
// ///    * all indicies (parameters and callback values) are specified in terms of byte positions within the string
// ///    * match and capture values are returned in the callback as lua strings
// ///  * if `text` is an `hs.text.utf16` object:
// ///    * the regular expression is applied to a copy of the object, so it is safe to modify the object within the callback.
// ///    * all indicies (parameters and callback values) are specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and capture indicies if this might be an issue for your purposes.
// ///    * match and capture values are returned in the callback as `hs.text.utf16` objects
// static int regex_matchWithCallback(lua_State *L) {
//     LuaSkin *skin = [LuaSkin sharedWithState:L] ;
//     [skin checkArgs:LS_TUSERDATA, REGEX_UD_TAG,
//                     LS_TANY, // checked below
//                     LS_TFUNCTION,
//                     LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
//                     LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
//                     LS_TBREAK] ;
//
//     HSRegularExpression *regex       = [skin toNSObjectAtIndex:1] ;
//     NSString            *textUTF16   = nil ;
//     const char          *textUTF8    = NULL ;
//     lua_Integer         length       = 0 ;
//     int                 callbackFn   = LUA_NOREF ;
//
//     BOOL                textIsUD     = (lua_type(L, 2) == LUA_TUSERDATA) ;
//
//     if (textIsUD) {
//         [skin checkArgs:LS_TANY, LS_TUSERDATA, UTF16_UD_TAG, LS_TBREAK | LS_TVARARG] ;
//         HSTextUTF16Object *utf16Object = [skin toNSObjectAtIndex:2] ;
//         textUTF16 = [utf16Object.utf16string copy] ;
//         length    = (lua_Integer)textUTF16.length ;
//     } else {
//         [skin checkArgs:LS_TANY, LS_TSTRING, LS_TBREAK | LS_TVARARG] ;
//         size_t l = 0 ;
//         textUTF8 = lua_tolstring(L, 2, &l) ;
//         length = (lua_Integer)l ;
//     }
//
//     lua_pushvalue(L, 3) ;
//     callbackFn = [skin luaRef:refTable] ;
//
//     lua_Integer i = (lua_gettop(L) > 3) ? lua_tointeger(L, 4) :  1 ;
//     lua_Integer j = (lua_gettop(L) > 4) ? lua_tointeger(L, 5) : -1 ;
//
//     NSMatchingOptions options = (lua_gettop(L) > 5) ? (NSMatchingOptions)(lua_tointeger(L, 6)) : 0 ;
//
//     // adjust indicies per lua standards
//     if (i < 0) i = length + 1 + i ; // negative indicies are from string end
//     if (j < 0) j = length + 1 + j ; // negative indicies are from string end
//
//     // match behavior of utf8 functions that take indicies
//     if ((i < 1) || (i > length)) return luaL_error(L, "starting index out of range") ;
//     if ((j < 1) || (j > length)) return luaL_error(L, "ending index out of range") ;
//
//     NSString *stringToEnumerate = textUTF16 ;
//     if (!textIsUD) {
//         // it's stupid that I either have to add 3 lines of compiler pragmas or use (void *)(uintptr_t) to cast between
//         // (const char *) and (void *) -- ok, I get the irony(?) of taking four lines to explain it here, but this is
//         // in an effort to explain what's happening so hopefully I'll remember it or can search for it next time...
//         // see comments from https://stackoverflow.com/a/44356147 and https://stackoverflow.com/a/1846648
//         NSData *tmpDataBlock = [NSData dataWithBytesNoCopy:(void *)(uintptr_t)textUTF8 length:(NSUInteger)length freeWhenDone:NO] ;
//         stringToEnumerate    = [[NSString alloc] initWithData:tmpDataBlock encoding:NSUTF8StringEncoding] ;
//     }
//
//     // build map of NSString indicies to source indicies; a small waste for UTF16 objects, but necessary for lua's UTF8 strings
//     NSUInteger *indiciesMap = malloc(sizeof(NSUInteger) * stringToEnumerate.length) ;
//     BOOL i_needsAdjusting   = !textIsUD ;
//     BOOL j_needsAdjusting   = !textIsUD ;
//
//     for (NSUInteger n = 0 ; n < stringToEnumerate.length ; n++) {
//         if (textIsUD || (n == 0)) {
//             indiciesMap[n] = n ;
//         } else {
//             // UTF8 size:
//             //     1 byte  for U+0000  - U+007F
//             //     2 bytes for U+0080  - U+07FF
//             //     3 bytes for U+0800  - U+FFFF   (except for D800-DFFF, which UTF16 uses for surrogate pairs)
//             //     4 bytes for U+10000 - U+10FFFF (i.e. the surrogate pairs, so we add 2 to idx for each member, resulting in 4
//
//             NSUInteger idx = indiciesMap[n - 1] + 1 ; // assume one byte
//             unichar  ch1 = [stringToEnumerate characterAtIndex:(n - 1)] ;
//             if (CFStringIsSurrogateHighCharacter(ch1) || CFStringIsSurrogateLowCharacter(ch1)) {
//                 idx++ ; // make it two bytes for a surrogate member
//             } else {
//                 if (ch1 > 0x007f) idx++ ; // ok, it's at least in the two byte range
//                 if (ch1 > 0x07ff) idx++ ; // nope, it's in the three byte range
//             }
//             indiciesMap[n] = idx ;
//         }
//
//         // if i or j point to middle of multi-byte UTF8 character, this actually skips to the next good character...
//         // annoying, but I don't' think I can fix it short of implementing completely sepparate code for UTF8 and UTF16
//         // since macOS does everything internally as UTF16... wait and see how big of an issue this really is...
//         if (i_needsAdjusting && (i <= (lua_Integer)(indiciesMap[n] + 1))) {
//             i_needsAdjusting = NO ;
//             i = (lua_Integer)n + 1 ;
//         }
//
//         if (j_needsAdjusting && (j <= (lua_Integer)(indiciesMap[n] + 1))) {
//             j_needsAdjusting = NO ;
//             j = (lua_Integer)n + 1 ;
//         }
//     }
//
//     // now do the users bidding...
//     dispatch_async(dispatch_get_main_queue(), ^(void){
//         LuaSkin *_skin = [LuaSkin sharedWithState:NULL] ;
//         [regex enumerateMatchesInString:stringToEnumerate
//                                 options:options
//                                   range:NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1)))
//                              usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//
//
//
//         }] ;
//
//         [_skin luaUnref:refTable ref:callbackFn] ;
//
//         free(indiciesMap) ;
//     }) ;
//
//     lua_pushvalue(L, 1) ;
//     return 1 ;
// }

#pragma mark - Module Constants

/// hs.text.regex.expressionOptions
/// Constant
/// A table containing key-value pairs of the options which can be used when creating a regular expression object with [hs.text.regex.new](#new)
///
/// The options available are as follows:
///  * `allowCommentsAndWhitespace` - Ignore whitespace and #-prefixed comments in the pattern.
///  * `anchorsMatchLines`          - Allow `^` and `$` to match the start and end of lines, instead of just the start and end of the full text.
///  * `caseInsensitive`            - Match letters in the pattern independent of case.
///  * `dotMatchesLineSeparators`   - Allow `.` to match any character, including line separators.
///  * `ignoreMetacharacters`       - Treat the entire pattern as a literal string.
///  * `useUnicodeWordBoundaries`   - Use [Unicode TR#29](https://www.unicode.org/reports/tr29/) to specify word boundaries (otherwise, traditional regular expression word boundaries are used).
///  * `useUnixLineSeparators`      - Treat only `\n` as a line separator (otherwise, all standard line separators are used).
static int regex_regularExpressionOptions(lua_State *L) {
    lua_newtable(L) ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionCaseInsensitive) ;            lua_setfield(L, -2, "caseInsensitive") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionAllowCommentsAndWhitespace) ; lua_setfield(L, -2, "allowCommentsAndWhitespace") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionIgnoreMetacharacters) ;       lua_setfield(L, -2, "ignoreMetacharacters") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionDotMatchesLineSeparators) ;   lua_setfield(L, -2, "dotMatchesLineSeparators") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionAnchorsMatchLines) ;          lua_setfield(L, -2, "anchorsMatchLines") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionUseUnixLineSeparators) ;      lua_setfield(L, -2, "useUnixLineSeparators") ;
    lua_pushinteger(L, (lua_Integer)NSRegularExpressionUseUnicodeWordBoundaries) ;   lua_setfield(L, -2, "useUnicodeWordBoundaries") ;
    return 1 ;
}

/// hs.text.regex.matchOptions
/// Constant
/// A table containing key-value pairs of the options which can be used with match and replacement methods
///
/// The matchOptions available are as follows:
///  * `anchored`               - Specifies that matches are limited to those at the start of the search range.
///  * `reportCompletion`       - When using [hs.text.regex:matchWithCallback](#matchWithCallback) or [hs.text.regex:replaceWithCallback](#replaceWithCallback), specifies that the callback will be invoked after completion with a final status. Has no effect when used with other methods.
///  * `reportProgress`         - When using [hs.text.regex:matchWithCallback](#matchWithCallback) or [hs.text.regex:replaceWithCallback](#replaceWithCallback), specifies that the callback will be invoked periodically during long running operations, even if no new results have yet been discovered. Has no effect when used with other methods.
///  * `withoutAnchoringBounds` - Specifies that `^` and `$` will not automatically match the beginning and end of the search range, but will still match the beginning and end of the entire string. This has no effect if the search range specifies the entire string.
///  * `withTransparentBounds`  - Specifies that matching may examine parts of the string beyond the bounds of the search range, for purposes such as word boundary detection, lookahead, etc. This has no effect if the search range specifies the entire string.
static int regex_matchingOptions(lua_State *L) {
    lua_newtable(L) ;
    lua_pushinteger(L, (lua_Integer)NSMatchingReportProgress) ;         lua_setfield(L, -2, "reportProgress") ;
    lua_pushinteger(L, (lua_Integer)NSMatchingReportCompletion) ;       lua_setfield(L, -2, "reportCompletion") ;
    lua_pushinteger(L, (lua_Integer)NSMatchingAnchored) ;               lua_setfield(L, -2, "anchored") ;
    lua_pushinteger(L, (lua_Integer)NSMatchingWithTransparentBounds) ;  lua_setfield(L, -2, "withTransparentBounds") ;
    lua_pushinteger(L, (lua_Integer)NSMatchingWithoutAnchoringBounds) ; lua_setfield(L, -2, "withoutAnchoringBounds") ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSRegularExpression(lua_State *L, id obj) {
    HSRegularExpression *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSRegularExpression *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, REGEX_UD_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

static id toHSRegularExpressionFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    HSRegularExpression *value ;
    if (luaL_testudata(L, idx, REGEX_UD_TAG)) {
        value = get_objectFromUserdata(__bridge HSRegularExpression, L, idx, REGEX_UD_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", REGEX_UD_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    HSRegularExpression *obj = [skin luaObjectAtIndex:1 toClass:"HSRegularExpression"] ;
    NSString *title = obj.pattern ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", REGEX_UD_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, REGEX_UD_TAG) && luaL_testudata(L, 2, REGEX_UD_TAG)) {
        LuaSkin *skin = [LuaSkin sharedWithState:L] ;
        HSRegularExpression *obj1 = [skin luaObjectAtIndex:1 toClass:"HSRegularExpression"] ;
        HSRegularExpression *obj2 = [skin luaObjectAtIndex:2 toClass:"HSRegularExpression"] ;
        lua_pushboolean(L, ([obj1.pattern isEqualToString:obj2.pattern] && (obj1.options == obj2.options))) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSRegularExpression *obj = get_objectFromUserdata(__bridge_transfer HSRegularExpression, L, 1, REGEX_UD_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
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
    {"pattern",             regex_pattern},
    {"options",             regex_options},
    {"captureCount",        regex_captureCount},

    {"gsubIn",              regex_gsubIn},
    {"firstMatch",          regex_firstMatch},

//     {"matchWithCallback",   regex_matchWithCallback},
//     {"replaceWithCallback", regesxreplaceWithCallback},

    {"__tostring",          userdata_tostring},
    {"__eq",                userdata_eq},
    {"__gc",                userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"_new",            regex_new},
    {"escapedPattern",  regex_escapedPatternForString},
    {"escapedTemplate", regex_escapedTemplateForString},
    {NULL,              NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs_libtext_regex(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibraryWithObject:REGEX_UD_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    regex_regularExpressionOptions(L) ; lua_setfield(L, -2, "expressionOptions") ;
    regex_matchingOptions(L) ;          lua_setfield(L, -2, "matchOptions") ;

    [skin registerPushNSHelper:pushHSRegularExpression         forClass:"HSRegularExpression"];
    [skin registerLuaObjectHelper:toHSRegularExpressionFromLua forClass:"HSRegularExpression"
                                                    withUserdataMapping:REGEX_UD_TAG];

    return 1;
}
