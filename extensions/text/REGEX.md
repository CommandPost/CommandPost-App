hs.text.regex
=============

Provides proper regular expression support for lua strings and `hs.text.utf16` objects.

This submodule provides more complete and proper regular expression functionality as provided by the macOS Objective-C runtime.

A full breakdown of the regular expression syntax is beynd the scope of this document, but a formal description of the syntax supported can be found at http://userguide.icu-project.org/strings/regexp.

Note that the Lua Pattern Matching supported by `string.match`, `string.gmatch`, `string.find`, and `string.gsub` is syntatically different from regular expression syntax; however, regular expressions provide much more flexibility and are significantly more portable across other programming languages and platforms.

Wrappers for the `string` library functions identified above are provided (using regular expression syntax), and can be used with both lua strings and `hs.text.utf16` objects, but you are not limited to their use.

The backslash (`\`) is the primary metacharacter sequence identifier for regular expressions; because Lua uses this for its own escape sequences, it is recommended that you use Lua's block quotes when defining patterns for clarity (e.g. `[[\w+]]` instead of `"\\w+"`). Examples provided within this submodule's documentation will primarily use this block quote syntax.

### Usage
~~~lua
regex = require("hs.text").regex
~~~

### Contents


##### Module Constructors
* <a href="#new">regex.new(pattern, [options]) -> regexObject</a>

##### Module Functions
* <a href="#escapedPattern">regex.escapedPattern(pattern) -> string</a>
* <a href="#escapedTemplate">regex.escapedTemplate(template) -> string</a>

##### Module Methods
* <a href="#captureCount">regex:captureCount() -> integer</a>
* <a href="#findIn">regex:findIn(pattern, [i]) -> start, end, [captures...] | nil</a>
* <a href="#firstMatch">regex:firstMatch(text, [i], [j], [options]) -> table | nil</a>
* <a href="#gmatchIn">regex:gmatchIn(text, [i]) -> function</a>
* <a href="#gsubIn">regex:gsubIn(text, template, [n]) -> updatedText, count</a>
* <a href="#matchIn">regex:matchIn(text, [i]) -> match(es) | nil</a>
* <a href="#options">regex:options() -> integer</a>
* <a href="#pattern">regex:pattern() -> string</a>

##### Module Constants
* <a href="#expressionOptions">regex.expressionOptions</a>
* <a href="#matchOptions">regex.matchOptions</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
regex.new(pattern, [options]) -> regexObject
~~~
Create a new `hs.text.regex` object with the specified regular expression

Parameters:
 * `pattern` - a lua string specifying the regular expression
 * `options` - an optional integer or table of integers and strings corresponding to values in the [hs.text.regex.expressionOptions](#expressionOptions) constant.
   * if `options` is an integer, it should a combination of 1 or more of the numeric values in the [hs.text.regex.expressionOptions](#expressionOptions) constant logically OR'ed together (e.g. `hs.text.regex.expressionOptions.caseInsensitive | hs.text.regex.expressionOptions.ignoreMetacharacters`)
   * if `options` is a table, each element of the array table should be a number value from the [hs.text.regex.expressionOptions](#expressionOptions) constant or a string matching one of the constant's keys. This method will logically OR the appropriate values together for you (e.g. `{"caseInsensitive", "ignoreMetacharacters"}`)

Returns:
 * a new regexObject, or nil if there is an error in the regular expression

Notes:
 * The regular expression syntax supported by this module is described in detail at http://userguide.icu-project.org/strings/regexp
 * Any error encountered when creating the regular expression object will be logged to the Hammerspoon console and this method will return nil.

### Module Functions

<a name="escapedPattern"></a>
~~~lua
regex.escapedPattern(pattern) -> string
~~~
Returns a lua string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters

Parameters:
 * `pattern` -- a lua string specifying the pattern string in which to escape metacharacters.

Returns:
 * a lua string

Notes:
 * this would typically be used when crafting a larger pattern string for use with [hs.text.regex.new](#new) and want to make sure that this sections is matched *exactly* and not treated as regular expression metacharacters.
 * e.g. `hs.text.regex.escapedPattern("(N/A)")` returns `"\(N\/A\)"`

- - -

<a name="escapedTemplate"></a>
~~~lua
regex.escapedTemplate(template) -> string
~~~
Returns a lua string by adding backslash escapes as necessary to protect any characters that would match as template pattern metacharacters

Parameters:
 * `template` -- a lua string specifying the template string in which to escape metacharacters.

Returns:
 * a lua string

Notes:
 * this would typically be used when crafting a larger template string for use with substitution methods and want to make sure that this sections is replaced *exactly* and not expanded based on expression captures.
 * e.g. `hs.text.regex.escapedTemplate("$1")` returns `"\$1"`

### Module Methods

<a name="captureCount"></a>
~~~lua
regex:captureCount() -> integer
~~~
Returns the number of capture groups specified by the regular expression defining this object.

Parameters:
 * None

Returns:
 * an integer specifying the number of capture groups defined by the regular expression object.

- - -

<a name="findIn"></a>
~~~lua
regex:findIn(pattern, [i]) -> start, end, [captures...] | nil
~~~
Apply the regular expression to the provided text and returns the indicies first match for use like `string.find`.

Parameters:
 * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
 * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.

Returns:
 * If a match is found, returns the starting and ending indicies of the match (as integers); if captures are specified in the pattern, also returns each capture after the indicies. If no match is found, returns nil.

Notes:
 * Unlike `string.find`, this method does not have a `plain` parameter. If you wish to perform a "plain" find operation, use the [hs.text.regex.expressionOptions.ignoreMetacharacters](#expressionOptions) option when creating the regular expression.

 * if `text` is a lua string:
   * captures (if any) will be returned as lua strings
   * `i` should be specified in terms of byte positions within the string.
   * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
 * if `text` is an `hs.text.utf16` object:
   * captures (if any) will be returned as `hs.text.utf16` objects
   * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.

- - -

<a name="firstMatch"></a>
~~~lua
regex:firstMatch(text, [i], [j], [options]) -> table | nil
~~~
Returns the first match of the regular expression within the specified range of the text.

Paramters:
 * `text`     - the text to apply the regular expression to, privded as a lua string or `hs.text.utf16` object.
 * `i`        - an optional integer, default 1, specifying the starting index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
 * `j`        - an optional integer, default -1, specifying the ending index of the range of `text` that the regular expression should be applied to; negative indicies are counted from the end of the text. If you wish to specify this parameter, you *must* provide a value for `i`.
 * `options` - an optional integer, default 0. The integer should a combination of 1 or more of the numeric values in the [hs.text.regex.matchOptions](#matchOptions) constant logically OR'ed together (e.g. `hs.text.regex.matchOptions.withoutAnchoringBounds | hs.text.regex.matchOptions.withTransparentBounds`). If you wish to specify this parameter, you *must* provide a value for both `i` and `j`.

Returns:
 * If the pattern is not found within the specified range of the text, returns nil.
 * If the pattern is found and no captures were specified in the pattern, then the table returned will have the starting index of the matched pattern within the text as its first element and the ending index as its second element.
 * If the pattern is found and specified captures, then the table returned will contain tables for each capture, specifying the starting and ending indicies of each capture in the order they were specified within the pattern. A table at index 0 will contain the starting and ending indicies of the entire match. If a given capture is empty, its position within the returned table will be `nil`.

Notes:
 * if `text` is a lua string:
   * all indicies (parameters and returned values) are specified in terms of byte positions within the string.
   * if `i` or `j` fall within the middle of a composite UTF8 byte sequence, they will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
 * if `text` is an `hs.text.utf16` object:
   * all indicies (parameters and callback values) are specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and capture indicies if this might be an issue for your purposes.

- - -

<a name="gmatchIn"></a>
~~~lua
regex:gmatchIn(text, [i]) -> function
~~~
Apply the regular expression to the provided text and return an iterator function for use like `string.gmatch`.

Parameters:
 * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
 * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.

Returns:
 * an iterator function

Notes:
 * The iterator function is defined such that each time it is called, it will return the next captures from the pattern over the object. If the pattern specifies no captures, then the whole match is produced in each call.
 * Most commonly this will be used as the iterator in a `for` loop, e.g.

    ```
    t = {}
    r = hs.text.regex.new([[(\w+)=(\w+)]])
    for k, v in r:gmatchIn("from=world, to=Lua") do
      t[k] = v
    end
    ```

 * if `text` is a lua string:
   * `i` should be specified in terms of byte positions within the string.
   * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
 * if `text` is an `hs.text.utf16` object:
   * a copy is made before creating the iterator so it is safe to modify the original object from within a loop using the iterator function.
   * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.

- - -

<a name="gsubIn"></a>
~~~lua
regex:gsubIn(text, template, [n]) -> updatedText, count
~~~
Return a gopy of the text where occurrences of the regex pattern have been replaced; global substitution for use like `string.gsub`.

Paramters:
 * `text`        - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
 * `template`    - a lua string, `hs.text.utf16` object, table, or function which specifies replacement(s) for pattern matches.
   * if `template` is a string or `hs.text.utf16` object, then its value is used for replacement.
   * if `template` is a table, the table is queried for every match using the first capture (if captures are specified) or the entire match (if no captures are specified). Keys in the table must be lua strings or `hs.text.utf16` objects, and values must be lua strings, numbers, or `hs.text.utf16` objects. If no key matches the capture, no replacement of the match occurs.
   * if `template` is a function, the function will be called with all of the captured substrings passed in as lua strings or `hs.text.utf16` objects (based upon the type for `text`) in order (or the entire match, if no captures are specified). The return value is used as the repacement of the match and must be `nil`, a lua string, a number, or a `hs.text.utf16` object. If the return value is `nil`, no replacement of the match occurs.
 * `n`           - an optional integer specifying the maximum number of replacements to perform. If this is not specified, all matches in the object will be replaced.

Returns:
 * a new lua string or `hs.text.utf16` object (based upon the type for `text`) with the substitutions specified, followed by an integer indicating the number of substitutions that occurred.

Notes:
 * If `template` is a lua string or `hs.text.utf16` object, any sequence in the replacement of the form `$n` where `n` is an integer >= 0 will be replaced by the `n`th capture from the pattern (`$0` specifies the entire match). A `$` not followed by a number is treated as a literal `$`. To specify a literal `$` followed by a numeric digit, escape the dollar sign (e.g. `\$1`).
   * If you are concerned about possible meta-characters in the template that you wish to be treated literally, see [hs.text.regex.escapedTemplate](#escapedTemplate).

 * The following examples are from the Lua documentation for `string.gsub` modified with the proper syntax:

     ~~~
     x = hs.text.regex.new("(\\w+)"):gsubIn("hello world", "$1 $1")
     -- x will equal "hello hello world world"

     -- note that if we use Lua's block quotes (e.g. `[[` and `]]`), then we don't have to escape the backslash:

     x = hs.text.regex.new([[\w+]]):gsubIn("hello world", "$0 $0", 1)
     -- x will equal "hello hello world"

     x = hs.text.regex.new([[(\w+)\s*(\w+)]]):gsubIn("hello world from Lua", "$2 $1")
     -- x will equal "world hello Lua from"

     x = hs.text.regex.new([[\$(\w+)]]):gsubIn("home = $HOME, user = $USER", function(a) return os.getenv(tostring(a)) end)
     -- x will equal "home = /Users/username, user = username"

     x = hs.text.regex.new([[\$(.+)\$]]):gsubIn("4+5 = $return 4+5$", function (s) return load(tostring(s))() end)
     -- x will equal "4+5 = 9"

     local t = {name="lua", version="5.3"}
     x = hs.text.regex.new([[\$(\w+)]]):gsubIn("$name-$version.tar.gz", t)
     -- x will equal "lua-5.3.tar.gz"
     ~~~

- - -

<a name="matchIn"></a>
~~~lua
regex:matchIn(text, [i]) -> match(es) | nil
~~~
Apply the regular expression to the provided text and returns the first match for use like `string.match`.

Parameters:
 * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
 * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.

Returns:
 * If a match is found and the pattern specifies captures, returns each capture; if no captures are specified, returns the entire match. If no matche is found, returns nil.

Notes:
 * if `text` is a lua string:
   * the returned match or captures will be returned as lua strings
   * `i` should be specified in terms of byte positions within the string.
   * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
 * if `text` is an `hs.text.utf16` object:
   * the returned match or captures will be returned as `hs.text.utf16` objects
   * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.

- - -

<a name="options"></a>
~~~lua
regex:options() -> integer
~~~
Returns the options specified when this regular expression object was created

Parameters:
 * None

Returns:
 * an integer containing logically OR'ed values from the [hs.text.regex.expressionOptions](#expressionOptions) constant specifying the options that were specified when this object was created.

- - -

<a name="pattern"></a>
~~~lua
regex:pattern() -> string
~~~
Returns the string representation of the regular expression specified when this regular expression object was created

Parameters:
 * None

Returns:
 * a lua string

### Module Constants

<a name="expressionOptions"></a>
~~~lua
regex.expressionOptions
~~~
A table containing key-value pairs of the options which can be used when creating a regular expression object with [hs.text.regex.new](#new)

The options available are as follows:
 * `allowCommentsAndWhitespace` - Ignore whitespace and #-prefixed comments in the pattern.
 * `anchorsMatchLines`          - Allow `^` and `$` to match the start and end of lines, instead of just the start and end of the full text.
 * `caseInsensitive`            - Match letters in the pattern independent of case.
 * `dotMatchesLineSeparators`   - Allow `.` to match any character, including line separators.
 * `ignoreMetacharacters`       - Treat the entire pattern as a literal string.
 * `useUnicodeWordBoundaries`   - Use [Unicode TR#29](https://www.unicode.org/reports/tr29/) to specify word boundaries (otherwise, traditional regular expression word boundaries are used).
 * `useUnixLineSeparators`      - Treat only `\n` as a line separator (otherwise, all standard line separators are used).

- - -

<a name="matchOptions"></a>
~~~lua
regex.matchOptions
~~~
A table containing key-value pairs of the options which can be used with match and replacement methods

The matchOptions available are as follows:
 * `anchored`               - Specifies that matches are limited to those at the start of the search range.
 * `reportCompletion`       - When using [hs.text.regex:matchWithCallback](#matchWithCallback) or [hs.text.regex:replaceWithCallback](#replaceWithCallback), specifies that the callback will be invoked after completion with a final status. Has no effect when used with other methods.
 * `reportProgress`         - When using [hs.text.regex:matchWithCallback](#matchWithCallback) or [hs.text.regex:replaceWithCallback](#replaceWithCallback), specifies that the callback will be invoked periodically during long running operations, even if no new results have yet been discovered. Has no effect when used with other methods.
 * `withoutAnchoringBounds` - Specifies that `^` and `$` will not automatically match the beginning and end of the search range, but will still match the beginning and end of the entire string. This has no effect if the search range specifies the entire string.
 * `withTransparentBounds`  - Specifies that matching may examine parts of the string beyond the bounds of the search range, for purposes such as word boundary detection, lookahead, etc. This has no effect if the search range specifies the entire string.

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
