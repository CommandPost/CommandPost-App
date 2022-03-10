hs.text
=======

This module provides functions and methods for converting text between the various encodings supported by macOS.

This module allows the import and export of text conforming to any of the encodings supported by macOS. Additionally, this module provides methods foc converting between encodings and attempting to identify the encoding of raw data when the original encoding may be unknown.

Because the macOS natively treats all textual data as UTF-16, additional support is provided in the `hs.text.utf16` submodule for working with textual data that has been converted to UTF16.

For performance reasons, the text objects are maintained as macOS native objects unless explicitely converted to a lua string with [hs.text:rawData](#rawData) or [hs.text:tostring](#tostring).


### Installation

*See https://github.com/asmagill/hammerspoon_asm/blob/master/README.md for details about building this module as a Universal library*

A precompiled version of this module can be found in this directory with a name along the lines of `text-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/text-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way is to clone this repository and then do the following:

~~~sh
$ cd wherever-you-downloaded-or-cloned-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

### Usage
~~~lua
text = require("hs.text")
~~~

### Contents

##### Submodules
* [hs.text.http](HTTP.md) - Perform HTTP requests with hs.text objects
* [hs.text.regex](REGEX.md) - Provides proper regular expression support for lua strings and `hs.text.utf16` objects.
* [hs.text.utf16](UTF16.md) - Perform text manipulation on UTF16 objects created by the `hs.text` module.

##### Module Constructors
* <a href="#new">text.new(text, [encoding] | [lossy, [windows]]) -> textObject</a>
* <a href="#readFile">text.readFile(path, [encoding]) -> textObject | nil, errorString</a>

##### Module Functions
* <a href="#encodingName">text.encodingName(encoding) -> string</a>

##### Module Methods
* <a href="#asEncoding">text:asEncoding(encoding, [lossy]) -> textObject | nil</a>
* <a href="#byte">text:byte([i, [j]]) -> 0 or more integeres</a>
* <a href="#encoding">text:encoding() -> integer</a>
* <a href="#encodingLossless">text:encodingLossless() -> boolean</a>
* <a href="#encodingValid">text:encodingValid() -> boolean</a>
* <a href="#fastestEncoding">text:fastestEncoding() -> integer</a>
* <a href="#guessEncoding">text:guessEncoding([lossy], [windows]) -> integer, boolean</a>
* <a href="#len">text:len() -> integer</a>
* <a href="#rawData">text:rawData() -> string</a>
* <a href="#smallestEncoding">text:smallestEncoding() -> integer</a>
* <a href="#toUTF16">text:toUTF16([lossy]) -> utf16TextObject | nil</a>
* <a href="#tostring">text:tostring([lossy]) -> string</a>
* <a href="#validEncodings">text:validEncodings([lossy]) -> table of integers</a>
* <a href="#writeToFile">text:writeToFile(path, [encoding]) -> textObject | nil, errorString</a>

##### Module Constants
* <a href="#encodingTypes">text.encodingTypes</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
text.new(text, [encoding] | [lossy, [windows]]) -> textObject
~~~
Creates a new text object from a lua string or `hs.text.utf16` object.

Params:
 * `text`      - a lua string or `hs.text.utf16` object. When this parameter is an `hs.text.utf16` object, no other parameters are allowed.
 * `encoding`  - an optional integer, specifying the encoding of the contents of the lua string. Valid encodings are contained within the [hs.text.encodingTypes](#encodingTypes) table.
 * If `encoding` is not provided, this contructor will attempt to guess the encoding (see [hs.text:guessEncoding](#guessEncoding) for more details).
   * `lossy`   - an optional boolean, defailt false, specifying whether or not characters can be removed or altered when guessing the encoding.
   * `windows` - an optional boolean, default false, specifying whether or not to consider encodings corresponding to Windows codepage numbers when guessing the encoding.

Returns:
 * a new textObject

Notes:
 * The contents of `text` is stored exactly as provided, even if the specified encoding (or guessed encoding) is not valid for the entire contents of the data.

- - -

<a name="readFile"></a>
~~~lua
text.readFile(path, [encoding]) -> textObject | nil, errorString
~~~
Create text object with the contents of the file at the specified path.

Parameters:
 * `path`     - a string specifying the absolute or relative (to your Hammerspoon configuration directory) path to the file to read.
 * `encoding` - an optional integer specifying the encoding of the data in the file. See [hs.text.encodingTypes](#encodingTypes) for possible values.

Returns:
 * a new textObject containing the contents of the specified file, or nil and a string specifying the error

Notes:
 * if no encoding is specified, the encoding will be determined by macOS when the file is read. If no encoding can be determined, the file will be read as if the encoding had been specified as [hs.text.encodingTypes.rawData](#encodingTypes)
   * to identify the encoding determined, see [hs.text:encoding](#encoding)

### Module Functions

<a name="encodingName"></a>
~~~lua
text.encodingName(encoding) -> string
~~~
Returns the localzed name for the encoding.

Parameters:
 * `encoding` - an integer specifying the encoding

Returns:
 * a string specifying the localized name for the encoding specified or an empty string if the number does not refer to a valid encoding.

Notes:
 * the name returned will match the name of one of the keys in [hs.text.encodingTypes](#encodingTypes) unless the system locale has changed since the module was first loaded.

### Module Methods

<a name="asEncoding"></a>
~~~lua
text:asEncoding(encoding, [lossy]) -> textObject | nil
~~~
Convert the textObject to a different encoding.

Parameters:
 * `encoding` - an integer specifying the new encoding. Valid encoding values can be looked up in [hs.text.encodingTypes](#encodingTypes)
 * `lossy`    - a optional boolean, defailt false, specifying whether or not characters can be removed or altered when converted to the new encoding.

Returns:
 * a new textObject with the text converted to the new encoding, or nil if the object cannot be converted to the new encoding.

Notes:
 * If the encoding is not 0 ([hs.text.encodingTypes.rawData](#encodingTypes)), the actual data in the new textObject may be different then the original if the new encoding represents the characters differently.

 * The encoding type 0 is special in that it creates a new textObject with the exact same data as the original but with no information as to the encoding type. This can be useful when the textObject has assumed an incorrect encoding and you wish to change it without loosing data. For example:

      ~~~
      a = hs.text.new("abcd")
      print(a:encoding(), #a, #(a:rawData()), a:tostring()) -- prints `1	4	4	abcd`

      b = a:asEncoding(hs.text.encodingTypes.UTF16)
      print(b:encoding(), #b, #(b:rawData()), b:tostring()) -- prints `10	4	10	abcd`
          -- note the change in the length of the raw data (the first two bytes will be the UTF16 BOM, but even factoring that out, the size went from 4 to 8), but not the text represented

      c = a:asEncoding(0):asEncoding(hs.text.encodingTypes.UTF16)
      print(c:encoding(), #c, #(c:rawData()), c:tostring()) -- prints `10	2	6	慢捤`
          -- note the change in the length of both the text and the raw data, as well as the actual text represented. Factoring out the UTF16 BOM, the data length is still 4, like the original object.
      ~~~

- - -

<a name="byte"></a>
~~~lua
text:byte([i, [j]]) -> 0 or more integeres
~~~
Get the actual bytes of data present between the specified indices of the textObject

Paramaters:
 * `i` - an optional integer, default 1, specifying the starting index. Negative numbers start from the end of the texObject.
 * `j` - an optional integer, defaults to the value of `i`, specifying the ending index. Negative numbers start from the end of the texObject.

Returns:
 * 0 or more integers representing the bytes within the range specified by the indicies.

Notes:
 * This is syntactic sugar for `string.bytes(hs.text:rawData() [, i [, j]])`
 * This method returns the byte values of the actual data present in the textObject. Depending upon the encoding of the textObject, these bytes may or may not represent individual or complete characters within the text itself.

- - -

<a name="encoding"></a>
~~~lua
text:encoding() -> integer
~~~
Returns the encoding currently assigned for the textObject

Parameters:
 * None

Returns:
 * an integer specifying the encoding

Notes:
 * the integer returned will correspond to an encoding defined in [hs.text.encodingTypes](#encodingTypes)

- - -

<a name="encodingLossless"></a>
~~~lua
text:encodingLossless() -> boolean
~~~
Returns whether or not the data representing the textObject is completely valid for the objects currently specified encoding with no loss or conversion of characters required.

Paramters:
 * None

Returns:
 * a boolean indicathing whether or not the data representing the textObject is completely valid for the objects currently specified encoding with no loss or conversion of characters required.

Notes:
 * for an encoding to be considered lossless, no data may be dropped or changed when evaluating the data within the requirements of the encoding. See also [hs.text:encodingValid](#encodingValid).
 * a textObject with an encoding of 0 (rawData) is always considered lossless (i.e. this method will return true)

- - -

<a name="encodingValid"></a>
~~~lua
text:encodingValid() -> boolean
~~~
Returns whether or not the current encoding is valid for the data in the textObject

Paramters:
 * None

Returns:
 * a boolean indicathing whether or not the encoding for the textObject is valid for the data in the textObject

Notes:
 * for an encoding to be considered valid by the macOS, it must be able to be converted to an NSString object within the Objective-C runtime. The resulting string may or may not be an exact representation of the data present (i.e. it may be a lossy representation). See also [hs.text:encodingLossless](#encodingLossless).
 * a textObject with an encoding of 0 (rawData) is always considered invalid (i.e. this method will return false)

- - -

<a name="fastestEncoding"></a>
~~~lua
text:fastestEncoding() -> integer
~~~
Returns the fastest encoding to which the textObject may be converted without loss of information.

Parameters:
 * None

Returns:
 * an integer specifying the encoding

Notes:
 * this method works with string representation of the textObject in its current encoding.
 * the integer returned will correspond to an encoding defined in [hs.text.encodingTypes](#encodingTypes)
 * “Fastest” applies to retrieval of characters from the string. This encoding may not be space efficient. See also [hs.text:smallestEncoding](#smallestEncoding).

- - -

<a name="guessEncoding"></a>
~~~lua
text:guessEncoding([lossy], [windows]) -> integer, boolean
~~~
Guess the encoding for the data held in the textObject

Paramters:
 * `lossy`   - an optional boolean, defailt false, specifying whether or not characters can be removed or altered when guessing the encoding.
 * `windows` - an optional boolean, default false, specifying whether or not to consider encodings corresponding to Windows codepage numbers when guessing the encoding.

Returns:
 * an integer specifying the guessed encoding and a boolean indicating whether or not the guess results in partial data loss (lossy)

Notes:
 * this method works with the raw data contents of the textObject and ignores the currently assigned encoding.
 * the integer returned will correspond to an encoding defined in [hs.text.encodingTypes](#encodingTypes)

- - -

<a name="len"></a>
~~~lua
text:len() -> integer
~~~
Returns the length of the textObject

Paramaters:
 * None

Returns:
 * an integer specifying the length of the textObject

Notes:
 * if the textObject's encoding is 0 (rawData), this method will return the number of bytes of data the textObject contains
 * otherwise, the length will be the number of characters the data represents in its current encoding.

- - -

<a name="rawData"></a>
~~~lua
text:rawData() -> string
~~~
Returns the raw data which makes up the contents of the textObject

Parameters:
 * None

Returns:
 * a lua string containing the raw data of the textObject

- - -

<a name="smallestEncoding"></a>
~~~lua
text:smallestEncoding() -> integer
~~~
Returns the smallest encoding to which the textObject may be converted without loss of information.

Parameters:
 * None

Returns:
 * an integer specifying the encoding

Notes:
 * this method works with string representation of the textObject in its current encoding.
 * the integer returned will correspond to an encoding defined in [hs.text.encodingTypes](#encodingTypes)
 * This encoding may not be the fastest for accessing characters, but is space-efficient. See also [hs.text:fastestEncoding](#fastestEncoding).

- - -

<a name="toUTF16"></a>
~~~lua
text:toUTF16([lossy]) -> utf16TextObject | nil
~~~
Returns a new hs.text.utf16 object representing the textObject for use with the `hs.text.utf16` submodule and its methods.

Parameters:
 * `lossy`    - a boolean, defailt false, specifying whether or not characters can be removed or altered in the conversion to UTF16.

Returns:
 * a new `hs.text.utf16` object or nil if the conversion could not be performed.

- - -

<a name="tostring"></a>
~~~lua
text:tostring([lossy]) -> string
~~~
Returns the textObject as a UTF8 string that can be printed and manipulated directly by lua.

Parameters:
 * `lossy`    - a boolean, defailt false, specifying whether or not characters can be removed or altered in the conversion to UTF8.

Returns:
 * a lua string containing the UTF8 representation of the textObject. The string will be empty (i.e. "") if the conversion to UTF8 could not be performed.

Notes:
 * this method is basically a wrapper for `textObject:asEncoding(hs.text.encodingTypes.UTF8, [lossy]):rawData()`

- - -

<a name="validEncodings"></a>
~~~lua
text:validEncodings([lossy]) -> table of integers
~~~
Generate a list of possible encodings for the data represented by the hs.text object

Paramters:
 * `lossy`   - an optional boolean, defailt false, specifying whether or not characters can be removed or altered when evaluating each potential encoding.

Returns:
 * a table of integers specifying identified potential encodings for the data. Each integer will correspond to an encoding defined in [hs.text.encodingTypes](#encodingTypes)

Notes:
 * this method works with the raw data contents of the textObject and ignores the currently assigned encoding.
 * the encodings identified are ones for which the bytes of data can represent valid character or formatting sequences within the encoding -- the specific textual representation for each encoding may differ. See the notes for [hs.text:asEncoding](#asEncoding) for an example of a byte sequence which has very different textual meanings for different encodings.

- - -

<a name="writeToFile"></a>
~~~lua
text:writeToFile(path, [encoding]) -> textObject | nil, errorString
~~~
Write the textObject to the specified file.

Parameters:
 * `path`     - a string specifying the absolute or relative (to your Hammerspoon configuration directory) path to save the data to.
 * `encoding` - an optional integer specifying the encoding to use when writing the file. If not specified, the current encoding of the textObject is used. See [hs.text.encodingTypes](#encodingTypes) for possible values.

Returns:
 * the textObject, or nil and a string specifying the error

### Module Constants

<a name="encodingTypes"></a>
~~~lua
text.encodingTypes
~~~
A table containing key-value pairs mapping encoding names to their integer representation used by the methods in this module.

This table will contain all of the encodings recognized by the macOS Objective-C runtime. Key values (strings) will be the localized name of the encoding based on the users locale at the time this module is loaded.

In addition to the localized names generated at load time, the following common encoding shorthands are also defined and are guaranteed to be consistent across all locales:

 * `rawData`           - The data of the textObject is treated as 8-bit bytes with no special meaning or encodings.
 * `ASCII`             - Strict 7-bit ASCII encoding within 8-bit chars; ASCII values 0…127 only.
 * `ISO2022JP`         - ISO 2022 Japanese encoding for email.
 * `ISOLatin1`         - 8-bit ISO Latin 1 encoding.
 * `ISOLatin2`         - 8-bit ISO Latin 2 encoding.
 * `JapaneseEUC`       - 8-bit EUC encoding for Japanese text.
 * `MacOSRoman`        - Classic Macintosh Roman encoding.
 * `NEXTSTEP`          - 8-bit ASCII encoding with NEXTSTEP extensions.
 * `NonLossyASCII`     - 7-bit verbose ASCII to represent all Unicode characters.
 * `ShiftJIS`          - 8-bit Shift-JIS encoding for Japanese text.
 * `Symbol`            - 8-bit Adobe Symbol encoding vector.
 * `Unicode`           - The canonical Unicode encoding for string objects.
 * `UTF16`             - A synonym for `Unicode`. The default encoding used by macOS and `hs.text.utf16` for direct manipulation of encoded text.
 * `UTF16BigEndian`    - UTF16 encoding with explicit endianness specified.
 * `UTF16LittleEndian` - UTF16 encoding with explicit endianness specified.
 * `UTF32`             - 32-bit UTF encoding.
 * `UTF32BigEndian`    - 32-bit UTF encoding with explicit endianness specified.
 * `UTF32LittleEndian` - 32-bit UTF encoding with explicit endianness specified.
 * `UTF8`              - An 8-bit representation of Unicode characters, suitable for transmission or storage by ASCII-based systems.
 * `WindowsCP1250`     - Microsoft Windows codepage 1250; equivalent to WinLatin2.
 * `WindowsCP1251`     - Microsoft Windows codepage 1251, encoding Cyrillic characters; equivalent to AdobeStandardCyrillic font encoding.
 * `WindowsCP1252`     - Microsoft Windows codepage 1252; equivalent to WinLatin1.
 * `WindowsCP1253`     - Microsoft Windows codepage 1253, encoding Greek characters.
 * `WindowsCP1254`     - Microsoft Windows codepage 1254, encoding Turkish characters.

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
