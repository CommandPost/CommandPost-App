hs._asm.undocumented.touchbar
=============================

This module and its submodules provide support for manipulating the Apple Touch Bar on newer Macbook Pro laptops. For machines that do not have a touchbar, the `hs._asm.undocumented.touchbar.virtual` submodule provides a method for mimicing one on screen.

Use of this module and its submodules in conunction with other third party applications that can create the virtual touchbar has not been tested specifically, but *should* work. I have not run into any problems or issues while using [Duet Display](https://www.duetdisplay.com), but haven't performed extensive testing.

This module and it's submodules require a mac that is running macOS 10.12.1 build 16B2657 or newer. If you wish to use this module in an environment where the end-user's machine may not have a new enough macOS release version, you should always check the value of [hs._asm.undocumented.touchbar.supported](#supported) before trying to create the Touch Bar and provide your own fallback or message. By supplying the argument `true` to this function, the user will be prompted to upgrade if necessary.

This module relies heavily on undocumented APIs in the macOS and may break with future OS updates. With minor updates and bug fixes, this module has continued to work through 10.15.2, and we hope to continue to maintain this, but no guarantees are given.

Bug fixes and feature updates are always welcome and can be submitted at https://github.com/asmagill/hs._asm.undocumented.touchbar.

This module is very experimental and is still under development, so the exact functions and methods may be subject to change without notice.

 Special thanks to @cmsj and @latenitefilms for code samples and bugfixes, and to @randomeizer, @Madd0g, and @medranocalvo for tests and reports. This is by no means a conclusive list, and if I've left anyone out, it's totally on me -- feel free to poke me with a (virtual) stick 😜.

### Installation

*See https://github.com/asmagill/hammerspoon_asm/blob/master/README.md for details about building this module as a Universal library*

A precompiled version of this module can be found in this directory with a name along the lines of `touchbar-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/touchbar-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way is to clone this repository (or you can individually download the `*.lua`, `*.m`, `*.h`, and `Makefile` files into a directory of your choice) and then do the following:

~~~sh
$ cd wherever-you-cloned-or-downloaded-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

### Usage
~~~lua
touchbar = require("hs._asm.undocumented.touchbar")
~~~

### Submodules

* [hs._asm.undocumented.touchbar.bar](README-BAR.md)
* [hs._asm.undocumented.touchbar.item](README-ITEM.md)
* [hs._asm.undocumented.touchbar.virtual](README-VIRTUAL.md)

### Contents


##### Module Functions
* <a href="#exists">touchbar.exists() -> boolean</a>
* <a href="#physical">touchbar.physical() -> boolean</a>
* <a name="size"></a>touchbar.size() -> sizeTable</a>
* <a href="#supported">touchbar.supported([showLink]) -> boolean</a>

- - -

### Module Functions

<a name="exists"></a>
~~~lua
touchbar.exists() -> boolean
~~~
Returns whether or not the touchbar exists on this machine, real *or* virtual.

Parameters:
 * None

Returns:
 * a boolean value indicating whether or a not the touchbar exists (true) or does not exist (false) on this machine.

Notes:
 * Checking the value of this function does not indicate whether or not the machine *can* support the Touch Bar but rather if it is *currently* supporting the Touch Bar; Use [hs._asm.undocumented.touchbar.supported](#supported) to check whether or not the machine *can* support the Touch Bar.

 * On machines with a physical touchbar (see also [hs._asm.undocumented.touchbar.physical](#physical)), this function will always return true.
 * On machines without a physical touchbar, this function will return true if a virtual touchbar has been created with the `hs._asm.undocumented.touchbar.virtual` submodule or through another third-party application.

- - -

<a name="physical"></a>
~~~lua
touchbar.physical() -> boolean
~~~
Returns whether or not the machine has a physical touchbar

Parameters:
 * None

Returns:
 * a boolean value indicating whether or not the machine has a physical touchbar (true) or does not (false)

Notes:
 * To determine if the machine is currently maintaining a touchbar, physical *or* virtual, use [hs._asm.undocumented.touchbar.exists](#exists).

- - -

<a name="size"></a>
~~~lua
touchbar.size() -> sizeTable
~~~
Returns the size of the touchbar as a size table

Parameters:
 * None

Returns:
 * a table containing key-value fields for the height (h) and width (w) of the touchbar

Notes:
 * On a machine without a physical touchbar, both height and width will be 0 if no virtual touchbar is currently active.
   * You can use this as a way to test if a third party application has created a virtual touchbar as long as you check **before** `hs._asm.undocumented.touchbar.virtual.new` has been used; once the virtual submodule's `new` function has been invoked, the height and width will match the virtual touchbar that Hammerspoon has created.

- - -

<a name="supported"></a>
~~~lua
touchbar.supported([showLink]) -> boolean
~~~
Returns a boolean value indicathing whether or not the Apple Touch Bar is supported on this Macintosh.

Parameters:
 * `showLink` - a boolean, default false, specifying whether a dialog prompting the user to download the necessary update is presented if Apple Touch Bar support is not found in the current Operating System.

Returns:
 * true if Apple Touch Bar support is found in the current Operating System or false if it is not.

Notes:
 * the link in the prompt is https://support.apple.com/kb/dl1897

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2020 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>

