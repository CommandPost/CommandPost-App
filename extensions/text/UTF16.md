hs.text.utf16
=============

Perform text manipulation on UTF16 objects created by the `hs.text` module.

This sumodule replicates many of the functions found in the lua `string` and `utf8` libraries but modified for use with UTF16 text objects.

Metamethods to make the objects work more like Lua strings:

 * unlike most userdata objects used by Hammerspoon modules, `hs.text.utf16` objects have their `__tostring` metamethod defined to return the UTF8 equivalent of the object. This allows the object to be printed to the Hammerspoon console directly with the lua `print` command (e.g. `print(object)`). You can also save the object as a lua string with `tostring(object)`.
 * (in)equality -- the metamethods for equality and inequality use [hs.text.utf16:compare({"literal"})](#compate) when you use `==`, `~=`, `<`, `<=`, `>`, or `>=` to compare a `hs.text.utf16` to another or to a lua string.
 * concatenation -- you can create a new `hs.utf16.text` objext by combining two objects (or one and a lua string) with `..`

Additional Notes

Internally, the macOS provides a wide range of functions for manipulating and managing UTF16 strings in the Objective-C runtime. While a wide variety of encodings can be used for importing and exporting data (see the main body of the `hs.text` module), string manipulation is provided by macOS only for the UTf16 representation of the encoded data. When working with data encoded in other formats, use the `hs.text:toUTF16()` method which will create an object his submodule can manipulate. When finished, you can convert the data back to the necessary encoding with the `hs.text.new()` function and then export the data back (e.g. writing to a file or posting to a URL).

In addition to the lua `string` and `utf8` functions, additional functions provided by the macOS are included. This includes, but is not limited to, Unicode normalization and ICU transforms.

### Usage
~~~lua
utf16 = require("hs.text").utf16
~~~

### Contents

##### Module Constructors
* <a href="#char">utf16.char(...) -> utf16TextObject</a>
* <a href="#new">utf16.new(text, [lossy]) -> utf16TextObject</a>

##### Module Functions
* <a href="#codepointForSurrogatePair">utf16.codepointForSurrogatePair(high, low) -> integer | nil</a>
* <a href="#isHighSurrogate">utf16.isHighSurrogate(unitchar) -> boolean</a>
* <a href="#isLowSurrogate">utf16.isLowSurrogate(unitchar) -> boolean</a>
* <a href="#surrogatePairForCodepoint">utf16.surrogatePairForCodepoint(codepoint) -> integer, integer | nil</a>

##### Module Methods
* <a href="#capitalize">utf16:capitalize([locale]) -> utf16TextObject</a>
* <a href="#characterCount">utf16:characterCount([composedCharacters], [i], [j]) -> integer | nil, integer</a>
* <a href="#codes">utf16:codes() -> iteratorFunction</a>
* <a href="#codpoint">utf16:codpoint([i], [j]) -> integer, ...</a>
* <a href="#compare">utf16:compare(text, [options], [locale]) -> -1 | 0 | 1</a>
* <a href="#composedCharacterRange">utf16:composedCharacterRange([i], [j]) -> start, end</a>
* <a href="#composedCharacters">utf16:composedCharacters() -> iteratorFunction</a>
* <a href="#copy">utf16:copy() -> utf16TextObject</a>
* <a href="#find">utf16:find(pattern, [i], [plain]) -> start, end, [captures...] | nil</a>
* <a href="#gmatch">utf16:gmatch(pattern, [i]) -> iteratorFunction</a>
* <a href="#gsub">utf16:gsub(pattern, replacement, [n]) -> utf16TextObject, count</a>
* <a href="#len">utf16:len() -> integer</a>
* <a href="#lower">utf16:lower([locale]) -> utf16TextObject</a>
* <a href="#match">utf16:match(pattern, [i]) -> match(es) | nil</a>
* <a href="#offset">utf16:offset([composedCharacters], n, [i]) -> integer | nil</a>
* <a href="#reverse">utf16:reverse() -> utf16TextObject</a>
* <a href="#sub">utf16:sub([i], [j]) -> utf16TextObject</a>
* <a href="#transform">utf16:transform(transform, [inverse]) -> utf16TextObject | nil</a>
* <a href="#unicodeComposition">utf16:unicodeComposition([compatibilityMapping]) -> utf16TextObject</a>
* <a href="#unicodeDecomposition">utf16:unicodeDecomposition([compatibilityMapping]) -> utf16TextObject</a>
* <a href="#unitCharacter">utf16:unitCharacter([i], [j]) -> integer, ...</a>
* <a href="#upper">utf16:upper([locale]) -> utf16TextObject</a>

##### Module Constants
* <a href="#builtInTransforms">utf16.builtInTransforms</a>
* <a href="#compareOptions">utf16.compareOptions</a>

- - -

### Module Constructors

<a name="char"></a>
~~~lua
utf16.char(...) -> utf16TextObject
~~~
Create a new utf16TextObject from the Unicode Codepoints specified.

Paramters:
 * zero or more Unicode Codepoints specified as integers

Returns:
 * a new utf16TextObject

Notes:
 * Unicode Codepoints are often written as `U+xxxx` where `xxxx` is between 4 and 6 hexadecimal digits. Lua can automatically convert hexadecimal numbers to integers, so replace the `U+` with `0x` when specifying codepoints in this format.

- - -

<a name="new"></a>
~~~lua
utf16.new(text, [lossy]) -> utf16TextObject
~~~
Create a new utf16TextObject from a lua string or `hs.text` object

Parameters:
 * `text`  - a lua string or `hs.text` object specifying the text for the new utf16TextObject
 * `lossy` - an optional boolean, default `false`, specifying whether or not characters can be removed or altered when converting the data to the UTF16 encoding.

Returns:
 * a new utf16TextObject, or nil if the data could not be encoded as a utf16TextObject

### Module Functions

<a name="codepointForSurrogatePair"></a>
~~~lua
utf16.codepointForSurrogatePair(high, low) -> integer | nil
~~~
Returns the Unicode Codepoint number for the specified high and low surrogate pair

Parameters:
 * `high` - an integer specifying the UTF16 "character" specifying the High Surrogate
 * `low` - an integer specifying the UTF16 "character" specifying the Low Surrogate

Returns:
 * if the `high` and `low` values specify a valid UTF16 surrogate pair, returns an integer specifying the codepoint for the pair; otherwise returns nil

Notes:
 * UTF16 represents Unicode characters in the range of U+010000 to U+10FFFF as a pair of UTF16 characters known as a surrogate pair. A surrogate pair is made up of a High Surrogate and a Low Surrogate.

* See also [hs.text.utf16.isHighSurrogate](#isHighSurrogate) and [hs.text.utf16.isLowSurrogate](#isLowSurrogate)

- - -

<a name="isHighSurrogate"></a>
~~~lua
utf16.isHighSurrogate(unitchar) -> boolean
~~~
Returns whether or not the specified 16-bit UTF16 unit character is a High Surrogate

Parameters:
 * `unitchar` - an integer specifying a single UTF16 character

Returns:
 * a boolean specifying whether or not the single UTF16 character specified is a High Surrogate (true) or not (false).

Notes:
 * UTF16 represents Unicode characters in the range of U+010000 to U+10FFFF as a pair of UTF16 characters known as a surrogate pair. A surrogate pair is made up of a High Surrogate and a Low Surrogate.
   * A high surrogate is a single UTF16 "character" with an integer representation between 0xD800 and 0xDBFF inclusive
   * A low surrogate is a single UTF16 "character" with an integer representation between 0xDC00 and 0xDFFF inclusive.
   * It is an encoding error if a high surrogate is not immediately followed by a low surrogate or for either surrogate type to be found by itself or surrounded by UTF16 characters outside of the surrogate pair ranges. However, most implementations silently ignore this and simply treat unpaired surrogates as unprintable (control characters) or equivalent to the Unicode Replacement character (U+FFFD).

* See also [hs.text.utf16.isLowSurrogate](#isLowSurrogate)

- - -

<a name="isLowSurrogate"></a>
~~~lua
utf16.isLowSurrogate(unitchar) -> boolean
~~~
Returns whether or not the specified 16-bit UTF16 unit character is a Low Surrogate

Parameters:
 * `unitchar` - an integer specifying a single UTF16 character

Returns:
 * a boolean specifying whether or not the single UTF16 character specified is a Low Surrogate (true) or not (false).

Notes:
 * UTF16 represents Unicode characters in the range of U+010000 to U+10FFFF as a pair of UTF16 characters known as a surrogate pair. A surrogate pair is made up of a High Surrogate and a Low Surrogate.
   * A high surrogate is a single UTF16 "character" with an integer representation between 0xD800 and 0xDBFF inclusive
   * A low surrogate is a single UTF16 "character" with an integer representation between 0xDC00 and 0xDFFF inclusive.
   * It is an encoding error if a high surrogate is not immediately followed by a low surrogate or for either surrogate type to be found by itself or surrounded by UTF16 characters outside of the surrogate pair ranges. However, most implementations silently ignore this and simply treat unpaired surrogates as unprintable (control characters) or equivalent to the Unicode Replacement character (U+FFFD).

* See also [hs.text.utf16.isHighSurrogate](#isHighSurrogate)

- - -

<a name="surrogatePairForCodepoint"></a>
~~~lua
utf16.surrogatePairForCodepoint(codepoint) -> integer, integer | nil
~~~
Returns the surrogate pair for the specified Unicode Codepoint

Parameters:
 * `codepoint` - an integer specifying the Unicode codepoint

Returns:
 * if the codepoint is between U+010000 to U+10FFFF, returns the UTF16 surrogate pair for the character as 2 integers; otherwise returns nil

Notes:
 * UTF16 represents Unicode characters in the range of U+010000 to U+10FFFF as a pair of UTF16 characters known as a surrogate pair. A surrogate pair is made up of a High Surrogate and a Low Surrogate.

* See also [hs.text.utf16.isHighSurrogate](#isHighSurrogate) and [hs.text.utf16.isLowSurrogate](#isLowSurrogate)

### Module Methods

<a name="capitalize"></a>
~~~lua
utf16:capitalize([locale]) -> utf16TextObject
~~~
Returns a copy of the utf16TextObject with all words capitalized.

Paramters:
 * `locale` - an optional string or boolean (default ommitted) specifying whether to consider localization when determining how to capitalize words.
   * if this parameter is ommitted, uses canonical (non-localized) mapping suitable for programming operations that require stable results not depending on the current locale.
   * if this parameter is the boolean `false` or `nil`, uses the system locale
   * if this parameter is the boolean `true`, uses the users current locale
   * if this parameter is a string, the locale specified by the string is used. (See `hs.host.locale.availableLocales()` for valid locale identifiers)

Returns:
 * a new utf16TextObject containing the capitalized version of the source

Notes:
 * For the purposes of this methif, a capitalized string is a string with the first character in each word changed to its corresponding uppercase value, and all remaining characters set to their corresponding lowercase values. A word is any sequence of characters delimited by spaces, tabs, or line terminators. Some common word delimiting punctuation isn’t considered, so this property may not generally produce the desired results for multiword strings.

- - -

<a name="characterCount"></a>
~~~lua
utf16:characterCount([composedCharacters], [i], [j]) -> integer | nil, integer
~~~
Returns the number of UTF16 characters in the utf16TextObject between the specified indicies.

Paramters:
 * `composedCharacters` - an optional boolean, default `false`, specifying whether or not composed character sequences should be treated as a single character (true) or count for as many individual UTF16 "characters" as are actually used to specify the sequence (false).
 * `i`                  - an optional integer, default 1, specifying the starting index of the UTF16 character to begin at; negative indicies are counted from the end of the string.
 * `j`                  - an optional integer, default -1, specifying the end of the range; negative indicies are counted from the end of the string.

Returns:
 * if no invalid sequences are found (see next), returns the number of Unicode characters in the range specified.
 * if an invalid sequence is found (specifically an isolated low or high surrogate or compoased character sequence that starts or ends outside of the specified range when `composedCharacters` is `true`, returns `nil` and the index position of the first invalid UTF16 character.

Notes:
 * This method is similar to lua's `utf8.len` and follows the same semantics -- if a specified index is out of range, a lua error is generated.
 * This method differs from [hs.text.uf16:len](#len) in that surrogate pairs count as one character and composed characters can optionally be considered a single character as well.

- - -

<a name="codes"></a>
~~~lua
utf16:codes() -> iteratorFunction
~~~
Returns an iterator function that returns the index position (in UTF16 characters) and codepoint of each character in the utf16TextObject.

Paramters:
 * None

Returns:
 * an iterator function which can be used with the lua `for` command as an iterator.

Notes:
 * This method is the utf16 equivalent of lua's `utf8.codes`.
 * Example usage:

     ~~~
     s = hs.text.utf16.new("Test 🙂 123")
     for p,c in s:codes() do print(p, string.format("U+%04x", c)) end
     ~~~

- - -

<a name="codpoint"></a>
~~~lua
utf16:codpoint([i], [j]) -> integer, ...
~~~
Returns the Unicode Codepoints for all characters in the utf16TextObject between the specified indicies.

Paramters:
 * `i` - an optional integer, default 1, specifying the starting index of the UTF16 character to begin at; negative indicies are counted from the end of the string.
 * `j` - an optional integer, default the value of `i`, specifying the end of the range; negative indicies are counted from the end of the string.

Returns:
 * zero or more integers representing the Unicode Codepoints of the UTF16 "character" at the indicies specified.

Notes:
 * This method is the utf16 equivalent of lua's `utf8.codepoint` and follows the same semantics -- if a specified index is out of range, a lua error is generated.
 * This method differs from [hs.text.uf16:unitCharacter](#unitCharacter) in that surrogate pairs will result in a single codepoint between U+010000 to U+10FFFF instead of two separate UTF16 characters.

- - -

<a name="compare"></a>
~~~lua
utf16:compare(text, [options], [locale]) -> -1 | 0 | 1
~~~
Compare the utf16TextObject to a string or another utf16TextObject and return the order

Paramters:
 * `text`    - a lua string or another utf16TextObject specifying the value to compare this object to
 * `options` - an optional integer or table of integers and strings corresponding to values in the [hs.text.utf16.compareOptions](#compareOptions) constant.
   * if `options` is an integer, it should a combination of 1 or more of the numeric values in the [hs.text.utf16.compareOptions](#compareOptions) constant logically OR'ed together (e.g. `hs.text.utf16.compareOptions.caseInsensitive | hs.text.utf16.compareOptions.numeric`)
   * if `options` is a table, each element of the array table should be a number value from the [hs.text.utf16.compareOptions](#compareOptions) constant or a string matching one of the constant's keys. This method will logically OR the appropriate values together for you (e.g. `{"caseInsensitive", "numeric"}`)
 * `locale`  - an optional string, booleam, or nil value specifying the locale to use when comparing.
   * if this parameter is ommitted, is an explicit `nil` or is the boolean value `false`, the system locale is used
   * if this parameter is a boolean value of `true`, the users current locale is used
   * if this paramter is a string, the locale specified by the string is used. (See `hs.host.locale.availableLocales()` for valid locale identifiers)

Returns:
 * -1 if `text` is ordered *after* the object (i.e. they are presented in ascending order)
 *  0 if `text` is ordered the same as the object (i.e. they are equal or equivalent, given the options)
 *  1 if `text` is ordered *before* the object (i.e. they are presented in descending order)

Notes:
 * The locale argument affects both equality and ordering algorithms. For example, in some locales, accented characters are ordered immediately after the base; other locales order them after “z”.
 * This method does *not* consider characters with composed character equivalences as identical or similar; if this is a concern, make sure to normalize the source and `text` as appropriate for your purposes with [hs.text.utf16.unicodeDecomposition](#unicodeDecomposition) or [hs.text.utf16.unicodeComposition](#unicodeComposition) before utilizing this method.

- - -

<a name="composedCharacterRange"></a>
~~~lua
utf16:composedCharacterRange([i], [j]) -> start, end
~~~
Returns the starting and ending index of the specified range, adjusting for composed characters or surrogate pairs at the beginning and end of the range.

Paramters:
 * `i` - an optional integer, default 1, specifying the starting index of the UTF16 character to begin at; negative indicies are counted from the end of the string.
 * `j` - an optional integer, default the value of `i`, specifying the end of the range; negative indicies are counted from the end of the string.

Returns:
 * the `start` and `end` indicies for the range of characters specified by the initial range

Notes:
 * if the unit character at index `i` specifies a low surrogate or is in the middle of a mulit-"character" composed character, `start` will be < `i`
 * likewise if `j` is in the middle of a multi-"character" composition or surrogate, `end` will be > `j`.

 * this method follows the semantics of `utf8.codepoint` -- if a specified index is out of range, a lua error is generated.

- - -

<a name="composedCharacters"></a>
~~~lua
utf16:composedCharacters() -> iteratorFunction
~~~
Returns an iterator function that returns the indicies of each character in the utf16TextObject, treating surrogate pairs and composed character sequences as single characters.

Paramters:
 * None

Returns:
 * an iterator function which can be used with the lua `for` command as an iterator.

Notes:
 * Example usage:

     ~~~
     s = hs.text.utf16.new("abc🙂123") .. hs.text.utf16.char(0x073, 0x0323, 0x0307) .. "xyz"
     for i,j in s:composedCharacters() do print(i, j, s:sub(i,j)) end
     ~~~

- - -

<a name="copy"></a>
~~~lua
utf16:copy() -> utf16TextObject
~~~
Create a copy of the utf16TextObject

Paramters:
 * None

Returns:
 * a copy of the utf16TextObject as a new object

- - -

<a name="find"></a>
~~~lua
utf16:find(pattern, [i], [plain]) -> start, end, [captures...] | nil
~~~
Looks for the first match of a pattern within the utf16TextObject and returns the indicies of the match

Paramters:
 * `pattern` - a lua string or utf16TextObject specifying the pattern for the match. See *Notes*.
 * `i`       - an optional integer, default 1, specifying the index of the utf16TextObject where the search for the pattern should begin; negative indicies are counted from the end of the object.
 * `plain`   - an optional boolean, default `false`, specifying that the pattern should be matched *exactly* (true) instead of treated as a regular expression (false).

Returns:
 * If a match is found, returns the starting and ending indicies of the match (as integers); if captures are specified in the pattern, also returns a new utf16TextObjects for each capture after the indicies. If no match is found, returns nil.

Notes:
 * This method is the utf16 equivalent of lua's `string.find` with one important caveat:
   * This method utilizes regular expressions as described at http://userguide.icu-project.org/strings/regexp, not the Lua pattern matching syntax.
   * Again, ***Lua pattern matching syntax will not work with this method.***

- - -

<a name="gmatch"></a>
~~~lua
utf16:gmatch(pattern, [i]) -> iteratorFunction
~~~
Returns an iterator function that iteratively returns the captures (if specified) or the entire match (if no captures are specified) of the pattern over the utf16TextObject.

Paramters:
 * `pattern` - a lua string or utf16TextObject specifying the regular expression to iteratively match over the utf16TextObject.
 * `i`       - an optional integer, default 1, specifying the starting character within the object for the search; negative indicies are counted from the end of the object.

Returns:
 * an iterator function which can be used with the lua `for` command as an iterator.

Notes:
 * This method is the utf16 equivalent of lua's `string.gmatch`.
 * This method uses the `hs.text.regex:gmatchIn` method with a copy of the original string, so it is safe to modify the original object within a loop.

 * The following examples are from the Lua documentation for `string.gmatch` modified with the proper syntax:

     ~~~
     -- print each word on a separate line
     s = hs.text.utf16.new("hello world from Lua")
     for w in s:gmatch([[\p{Alphabetic}+]]) do
       print(w)
     end

     -- collect all pairs key=value from the given string into a table:
     t = {}
     s = hs.text.utf16.new("from=world, to=Lua")
     for k, v in s:gmatch([[(\w+)=(\w+)]]) do
       t[tostring(k)] = tostring(v)
     end
     ~~~

- - -

<a name="gsub"></a>
~~~lua
utf16:gsub(pattern, replacement, [n]) -> utf16TextObject, count
~~~
Return a gopy of the object with occurances of the pattern replaced; global substitution.

Paramters:
 * `pattern`     - a lua string or utf16TextObject specifying the pattern for the match. See *Notes*.
 * `replacement` - a lua string, utf16TextObject, table, or function which specifies replacement(s) for pattern matches.
   * if `replacement` is a string or utf16TextObject, then its value is used for replacement.
   * if `replacement` is a table, the table is queried for every match using the first capture (if captures are specified) or the entire match (if no captures are specified). Keys in the table must be lua strings or utf16TextObjects, and values must be lua strings, numbers, or utf16TextObjects. If no key matches the capture, no replacement of the match occurs.
   * if `replacement` is a function, the function will be called with all of the captured substrings passed in as utf16TextObjects in order (or the entire match, if no captures are specified). The return value is used as the repacement of the match and must be `nil`, a lua string, a number, or a utf16TextObject. If the return value is `nil`, no replacement of the match occurs.
 * `n`           - an optional integer specifying the maximum number of replacements to perform. If this is not specified, all matches in the object will be replaced.

Returns:
 * a new utf16TextObject with the substitutions specified, followed by an integer specifying the number of substitutions that occurred.

Notes:
 * This method is the utf16 equivalent of lua's `string.gsub` with one important caveat:
   * This method utilizes regular expressions as described at http://userguide.icu-project.org/strings/regexp, not the Lua pattern matching syntax.
   * Again, ***Lua pattern matching syntax will not work with this method.***

 * If `replacement` is a lua string or `hs.text.utf16` object, any sequence in the replacement of the form `$n` where `n` is an integer >= 0 will be replaced by the `n`th capture from the pattern (`$0` specifies the entire match). A `$` not followed by a number is treated as a literal `$`. To specify a literal `$` followed by a numeric digit, escape the dollar sign (e.g. `\$1`).
   * If you are concerned about possible meta-characters in the replacement that you wish to be treated literally, see `hs.text.regex.escapedTemplate`.

 * The following examples are from the Lua documentation for `string.gsub` modified with the proper syntax:

     ~~~
     x = hs.text.utf16.new("hello world"):gsub("(\\w+)", "$1 $1")
     -- x will equal "hello hello world world"

     -- note that if we use Lua's block quotes (e.g. `[[` and `]]`), then we don't have to escape the backslash:

     x = hs.text.utf16.new("hello world"):gsub([[\w+]], "$0 $0", 1)
     -- x will equal "hello hello world"

     x = hs.text.utf16.new("hello world from Lua"):gsub([[(\w+)\s*(\w+)]], "$2 $1")
     -- x will equal "world hello Lua from"

     x = hs.text.utf16.new("home = $HOME, user = $USER"):gsub([[\$(\w+)]], function(a) return os.getenv(tostring(a)) end)
     -- x will equal "home = /Users/username, user = username"

     x = hs.text.utf16.new("4+5 = $return 4+5$"):gsub([[\$(.+)\$]], function (s) return load(tostring(s))() end)
     -- x will equal "4+5 = 9"

     local t = {name="lua", version="5.3"}
     x = hs.text.utf16.new("$name-$version.tar.gz"):gsub([[\$(\w+)]], t)
     -- x will equal "lua-5.3.tar.gz"
     ~~~

- - -

<a name="len"></a>
~~~lua
utf16:len() -> integer
~~~
Returns the length in UTF16 characters in the object

Parameters:
 * None

Returns:
 * the number of UTF16 characterss in the object

Notes:
 * This method is the utf16 equivalent of lua's `string.len`
 * Composed character sequences and surrogate pairs are made up of multiple UTF16 "characters"; see also [hs.text.utf16:characterCount](#characterCount) wihch offers more options.

- - -

<a name="lower"></a>
~~~lua
utf16:lower([locale]) -> utf16TextObject
~~~
Returns a copy of the utf16TextObject with an lowercase representation of the source.

Paramters:
 * `locale` - an optional string or boolean (default ommitted) specifying whether to consider localization when determining how change case.
   * if this parameter is ommitted, uses canonical (non-localized) mapping suitable for programming operations that require stable results not depending on the current locale.
   * if this parameter is the boolean `false` or `nil`, uses the system locale
   * if this parameter is the boolean `true`, uses the users current locale
   * if this parameter is a string, the locale specified by the string is used. (See `hs.host.locale.availableLocales()` for valid locale identifiers)

Returns:
 * a new utf16TextObject containing an lowercase representation of the source.

Notes:
 * This method is the utf16 equivalent of lua's `string.lower`
 * Case transformations aren’t guaranteed to be symmetrical or to produce strings of the same lengths as the originals.

- - -

<a name="match"></a>
~~~lua
utf16:match(pattern, [i]) -> match(es) | nil
~~~
Looks for the first match of a pattern within the utf16TextObject and returns it

Paramters:
 * `pattern` - a lua string or utf16TextObject specifying the pattern for the match. See *Notes*.
 * `i`       - an optional integer, default 1, specifying the index of the utf16TextObject where the search for the pattern should begin; negative indicies are counted from the end of the object.

Returns:
 * If a match is found and the pattern specifies captures, returns a new utf16TextObjects for each capture; if no captures are specified, returns the entire match as a new utf16TextObject. If no matche is found, returns nil.

Notes:
 * This method is the utf16 equivalent of lua's `string.match` with one important caveat:
   * This method utilizes regular expressions as described at http://userguide.icu-project.org/strings/regexp, not the Lua pattern matching syntax.
   * Again, ***Lua pattern matching syntax will not work with this method.***

- - -

<a name="offset"></a>
~~~lua
utf16:offset([composedCharacters], n, [i]) -> integer | nil
~~~
Returns the position (in UTF16 characters) where the encoding of the `n`th character of the utf16TextObject begins.

Paramters:
 * `composedCharacters` - an optional boolean, default `false` specifying whether or not composed character sequences should be considered as a single UTF16 character (true) or as the individual characters that make up the sequence (false).
 * `n`                  - an integer specifying the UTF16 character number to get the offset for, starting from position `i`. If `n` is negative, gets specifies the number of characters before position `i`.
 * `i`                  - an optional integer, default 1 when `n` is non-negative or [hs.text.utf16:len](#len) + 1 when `n` is negative, specifiying the starting character from which to count `n`.

Returns:
 * the index of the utf16TextObject where the `n`th character begins or nil if no such character exists. As a special case when `n` is 0, returns the offset of the start of the character that contains the `i`th UTF16 character of the utf16Text obejct.

Notes:
 * This method is the utf16 equivalent of lua's `utf8.offset`.

- - -

<a name="reverse"></a>
~~~lua
utf16:reverse() -> utf16TextObject
~~~
Returns a new utf16TextObject with the characters reveresed.

Parameters:
 * None

Returns:
 * a new utf16TextObject with the characters reveresed

Notes:
 * This method is the utf16 equivalent of lua's `string.reverse`
 * Surrogate pairs and composed character sequences are maintained, so the reversed object will be composed of valid UTF16 sequences (assuming, of course, that the original object was composed of valid UTF16 sequences)

- - -

<a name="sub"></a>
~~~lua
utf16:sub([i], [j]) -> utf16TextObject
~~~
Returns a new utf16TextObject containing a substring of the source object

Parameters:
 * `i` - an integer specifying the starting index of the substring; negative indicies are counted from the end of the string.
 * `j` - an optional integer, default -1, specifying the end of the substring; negative indicies are counted from the end of the string.

Returns:
 * a new utf16TextObject containing a substring of the source object as delimited by the indicies `i` and `j`

Notes:
 * This method is the utf16 equivalent of lua's `string.sub`
   * In particular, `hs.text.utf16:sub(1, j)` will return the prefix of the source with a length of `j`, and `hs.text.utf16:sub(-i)` returns the suffix of the source with a length of `i`.

 * This method uses the specific indicies provided, which could result in a broken surrogate or composed character sequence at the begining or end of the substring. If this is a concern, use [hs.text.utf16:composedCharacterRange](#composedCharacterRange) to adjust the range values before invoking this method.

- - -

<a name="transform"></a>
~~~lua
utf16:transform(transform, [inverse]) -> utf16TextObject | nil
~~~
Create a new utf16TextObject by applying the specified ICU transform

Paramters:
 * `transform` - a string specifying the ICU transform(s) to apply
 * `inverse`   - an optional boolean, default `false`, specifying whether or not to apply the inverse (or reverse) of the specified transformation

Returns:
 * a new utf16TextObject containing the transformed data, or nil if the transform (or its inverse) could not be applied or was invalid

Notes:
 * some built in transforms are identified in the constant table [hs.text.utf16.builtinTransforms](#builtInTransforms).
 * transform syntax is beyond the scope of this document; see http://userguide.icu-project.org/transforms/general for more information on creating your own transforms

 * Note that not all transforms have an inverse or are reversible.

- - -

<a name="unicodeComposition"></a>
~~~lua
utf16:unicodeComposition([compatibilityMapping]) -> utf16TextObject
~~~
Create a new utf16TextObject with the contents of the parent normalized using Unicode Normalization Form (K)C.

Paramters:
 * `compatibilityMapping` - an optionabl boolean, default `false`, specifying whether compatibility mapping (true) should be used (Normalization Form KC) or canonical mapping (false) should be used (Normalization Form C) when normalizing the text.

Returns:
 * a new utf16TextObject with the contents of the parent normalized using Unicode NormalizationForm (K)C.

Notes:
 * At its most basic, normalization is useful when comparing strings which may have been composed differently (e.g. a single UTF16 character representing an accented `á` vs the visually equivalent composed character sequence of an `a` followed by U+0301) or use stylized versions of characters or numbers (e.g. `1` vs `①`), but need to be compared for their "visual" or "intended" equivalance.

 * see http://www.unicode.org/reports/tr15/ for a more complete discussion of the various types of Unicode Normalization and the differences/strengths/weaknesses of each.

 * See also [hs.text.utf16:unicodeDecomposition](#unicodeDecomposition)

- - -

<a name="unicodeDecomposition"></a>
~~~lua
utf16:unicodeDecomposition([compatibilityMapping]) -> utf16TextObject
~~~
Create a new utf16TextObject with the contents of the parent normalized using Unicode Normalization Form (K)D.

Paramters:
 * `compatibilityMapping` - an optionabl boolean, default `false`, specifying whether compatibility mapping (true) should be used (Normalization Form KD) or canonical mapping (false) should be used (Normalization Form D) when normalizing the text.

Returns:
 * a new utf16TextObject with the contents of the parent normalized using Unicode NormalizationForm (K)D.

Notes:
 * At its most basic, normalization is useful when comparing strings which may have been composed differently (e.g. a single UTF16 character representing an accented `á` vs the visually equivalent composed character sequence of an `a` followed by U+0301) or use stylized versions of characters or numbers (e.g. `1` vs `①`), but need to be compared for their "visual" or "intended" equivalance.

 * see http://www.unicode.org/reports/tr15/ for a more complete discussion of the various types of Unicode Normalization and the differences/strengths/weaknesses of each.

 * See also [hs.text.utf16:unicodeComposition](#unicodeComposition)

- - -

<a name="unitCharacter"></a>
~~~lua
utf16:unitCharacter([i], [j]) -> integer, ...
~~~
Returns the UTF16 unit character codes for the range specified

Paramters:
 * `i` - an optional integer, default 1, specifying the starting indexof the UTF16 character to begin at; negative indicies are counted from the end of the string.
 * `j` - an optional integer, default the value of `i`, specifying the end of the range; negative indicies are counted from the end of the string.

Returns:
 * zero or more integers representing the individual utf16 "characters" of the object within the range specified

Notes:
 * this method returns the 16bit integer corresponding to the UTF16 "character" at the indicies specified. Surrogate pairs *are* treated as two separate "characters" by this method, so the initial or final character may be a broken surrogate -- see [hs.text.utf16.isHighSurrogate](#isHighSurrogate) and [hs.text.utf16.isLowSurrogate](#isLowSurrogate).

 * this method follows the semantics of `utf8.codepoint` -- if a specified index is out of range, a lua error is generated.

- - -

<a name="upper"></a>
~~~lua
utf16:upper([locale]) -> utf16TextObject
~~~
Returns a copy of the utf16TextObject with an uppercase representation of the source.

Paramters:
 * `locale` - an optional string or boolean (default ommitted) specifying whether to consider localization when determining how change case.
   * if this parameter is ommitted, uses canonical (non-localized) mapping suitable for programming operations that require stable results not depending on the current locale.
   * if this parameter is the boolean `false` or `nil`, uses the system locale
   * if this parameter is the boolean `true`, uses the users current locale
   * if this parameter is a string, the locale specified by the string is used. (See `hs.host.locale.availableLocales()` for valid locale identifiers)

Returns:
 * a new utf16TextObject containing an uppercase representation of the source.

Notes:
 * This method is the utf16 equivalent of lua's `string.upper`
 * Case transformations aren’t guaranteed to be symmetrical or to produce strings of the same lengths as the originals.

### Module Constants

<a name="builtInTransforms"></a>
~~~lua
utf16.builtInTransforms
~~~
Built in transormations which can be used with [hs.text.utf16:transform](#transform).

This table contains key-value pairs identifying built in transforms provided by the macOS Objective-C runtime environment for use with [hs.text.utf16:transform](#transform). See http://userguide.icu-project.org/transforms/general for a more complete discussion on how to specify your own transformations.

The built in transformations are:
 * `fullwidthToHalfwidth` - transform full-width CJK characters to their half-width forms. e.g. “マット” transforms to “ﾏｯﾄ”. This transformation is reversible.
 * `hiraganaToKatakana`   - transliterate the text from Hiragana script to Katakana script. e.g. “ひらがな” transliterates to “カタカナ”. This transformation is reversible.
 * `latinToArabic`        - transliterate the text from Latin script to Arabic script. e.g. “ạlʿarabīẗ‎” transliterates to “العَرَبِية”. This transformation is reversible.
 * `latinToCyrillic`      - transliterate the text from Latin script to Cyrillic script. e.g. “kirillica” transliterates to “кириллица”. This transformation is reversible.
 * `latinToGreek`         - transliterate the text from Latin script to Greek script. e.g. “Ellēnikó alphábēto‎” transliterates to “Ελληνικό αλφάβητο”. This transformation is reversible.
 * `latinToHangul`        - transliterate the text from Latin script to Hangul script. e.g. “hangul” transliterates to “한굴”. This transformation is reversible.
 * `latinToHebrew`        - transliterate the text from Latin script to Hebrew script. e.g. “ʻbryţ” transliterates to “עברית”. This transformation is reversible.
 * `latinToHiragana`      - transliterate the text from Latin script to Hiragana script. e.g. “hiragana” transliterates to “ひらがな”. This transformation is reversible.
 * `latinToKatakana`      - transliterate the text from Latin script to Katakana script. e.g. “katakana” transliterates to “カタカナ”. This transformation is reversible.
 * `latinToThai`          - transliterate the text from Latin script to Thai script. e.g. “p̣hās̄ʹā thịy” transliterates to “ภาษาไทย”. This transformation is reversible.
 * `mandarinToLatin`      - transliterate the text from Han script to Latin script. e.g. “hàn zì” transliterates to “汉字”.
 * `stripCombiningMarks`  - removes all combining marks (including diacritics and accents) from the text
 * `stripDiacritics`      - removes all diacritic marks from the text
 * `toLatin`              - transliterate all text possible to Latin script. Ideographs are transliterated as Mandarin Chinese.
 * `toUnicodeName`        - converts characters other than printable ASCII to their Unicode character name in braces. e.g. “🐶🐮” transforms to "\N{DOG FACE}\N{COW FACE}". This transformation is reversible.
 * `toXMLHex`             - transliterate characters other than printable ASCII to XML/HTML numeric entities. e.g. “❦” transforms to “&#x2766;”. This transformation is reversible.

- - -

<a name="compareOptions"></a>
~~~lua
utf16.compareOptions
~~~
A table containing the modifier options for use with the [hs.text.utf16:compare](#compare) method.

This table contains key-value pairs specifying the numeric values which should be logically OR'ed together (or listed individually in a table as either the integer or the key name) for use with the [hs.text.utf16:compare](#compare) method.

Valid options are as follows:
 * `caseInsensitive`      - sort order is case-insensitive
 * `diacriticInsensitive` - ignores diacritic marks
 * `finderFileOrder`      - sort order matches what the Finder uses for the locale specified. This is a convienence combination which is equivalent to `{ "caseInsensitive", "numeric", "widthInsensitive", "forcedOrdering" }`.
 * `forcedOrdering`       - comparisons are forced to return either -1 or 1 if the strings are equivalent but not strictly equal. (e.g.  “aaa” is greater than "AAA" if `caseInsensitive` is also set.)
 * `literal`              - exact character-by-character equivalence.
 * `numeric`              - numbers within the string are compared numerically. This only applies to actual numeric characters, not characters that would have meaning in a numeric representation such as a negative sign, a comma, or a decimal point.
 * `widthInsensitive`     - ignores width differences in characters that have full-width and half-width forms, common in East Asian character sets.

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2021 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>
