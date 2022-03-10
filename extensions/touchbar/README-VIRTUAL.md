hs._asm.undocumented.touchbar.virtual
=====================================

This submodule provides support for creating a virtual touchbar which can be displayed on the users screen.

While this submodule will be primarily of interest to those without a touchbar enabled mac, it can also be used on machines which *do* have a touchbar and is in fact required if you wish to create an image of the current contents of the touchbar -- see [hs._asm.undocumented.touchbar:image](#image).

This module is very experimental and is still under development, so the exact functions and methods may be subject to change without notice.

This submodule is based in heavily on code from the following sources:
* https://github.com/bikkelbroeders/TouchBarDemoApp - For the virtual touchbar itself (see [hs._asm.undocumented.touchbar.new](#new)). Unlike the code found at this link, we only support displaying the touch bar window on your computer screen and not on an attached iOS device.
* https://github.com/steventroughtonsmith/TouchBarScreenshotter/blob/master/TouchBarScreenshotter - for the code to create an image of the touchbar (see [hs._asm.undocumented.touchbar:image](#image))


### Installation

You can install the entire module and its submodules as described in [README.md](README.md).

### Usage
~~~lua
virtual = require("hs._asm.undocumented.touchbar").virtual
~~~

### Contents


##### Module Functions
* <a href="#new">virtual.new() -> touchbarObject | nil</a>

##### Module Methods
* <a href="#acceptsMouseEvents">virtual:acceptsMouseEvents([state]) -> boolean | touchbarObject</a>
* <a href="#atMousePosition">virtual:atMousePosition() -> touchbarObject</a>
* <a href="#backgroundColor">virtual:backgroundColor([color]) -> color | touchbarObject</a>
* <a href="#centered">virtual:centered([top]) -> touchbarObject</a>
* <a href="#getFrame">virtual:getFrame() -> table</a>
* <a href="#hide">virtual:hide([duration]) -> touchbarObject</a>
* <a href="#image">virtual:image() -> hs.image object | nil</a>
* <a href="#inactiveAlpha">virtual:inactiveAlpha([alpha]) -> number | touchbarObject</a>
* <a href="#isVisible">virtual:isVisible() -> boolean</a>
* <a href="#movable">virtual:movable([state]) -> boolean | touchbarObject</a>
* <a href="#setCallback">virtual:setCallback(fn | nil) -> touchbarObject</a>
* <a href="#show">virtual:show([duration]) -> touchbarObject</a>
* <a href="#show">virtual:streaming(state) -> touchbarObject</a>
* <a href="#toggle">virtual:toggle([duration]) -> touchbarObject</a>
* <a href="#topLeft">virtual:topLeft([point]) -> table | touchbarObject</a>

- - -

### Module Functions

<a name="new"></a>
~~~lua
virtual.new() -> touchbarObject | nil
~~~
Creates a new touchbarObject representing a window which displays the Apple Touch Bar.

Parameters:
 * None

Returns:
 * the touchbarObject or nil if one could not be created

Notes:
 * The most common reason a touchbarObject cannot be created is if your macOS version is not new enough. Type the following into your Hammerspoon console to check: `require("hs._asm.undocumented.touchbar").supported(true)`.

### Module Methods

<a name="acceptsMouseEvents"></a>
~~~lua
virtual:acceptsMouseEvents([state]) -> boolean | touchbarObject
~~~
Get or set whether or not the touch bar accepts mouse events.

Parameters:
 * `state` - an optional boolean which specifies whether the touch bar accepts mouse events (true) or not (false).  Default true.

Returns:
 * if an argument is provided, returns the touchbarObject; otherwise returns the current value.

Notes:
 * This method can be used to prevent mouse clicks in the touch bar from triggering the touch bar buttons.
 * This can be useful when [hs._asm.undocumented.touchbar.virtual:movable](#movable) is set to true to prevent accidentally triggering an action.

- - -

<a name="atMousePosition"></a>
~~~lua
virtual:atMousePosition() -> touchbarObject
~~~
Moves the touch bar window so that it is centered directly underneath the mouse pointer.

Parameters:
 * None

Returns:
 * the touchbarObject

Notes:
 * This method mimics the display location as set by the sample code this module is based on.  See https://github.com/bikkelbroeders/TouchBarDemoApp for more information.
 * The touch bar position will be adjusted so that it is fully visible on the screen even if this moves it left or right from the mouse's current position.

- - -

<a name="backgroundColor"></a>
~~~lua
virtual:backgroundColor([color]) -> color | touchbarObject
~~~
Get or set the background color for the touch bar window.

Parameters:
 * `color` - an optional color table as defined in `hs.drawing.color` specifying the background color for the touch bar window.  Defaults to black, i.e. `{ white = 0.0, alpha = 1.0 }`.

Returns:
 * if an argument is provided, returns the touchbarObject; otherwise returns the current value.

Notes:
 * The visual effect of this method is to change the border color around the touch bar -- the touch bar itself remains the color as defined by the application which is providing the current touch bar items for display.

- - -

<a name="centered"></a>
~~~lua
virtual:centered([top]) -> touchbarObject
~~~
Moves the touch bar window to the top or bottom center of the main screen.

Parameters:
 * `top` - an optional boolean, default false, specifying whether the touch bar should be centered at the top (true) of the screen or at the bottom (false).

Returns:
 * the touchbarObject

- - -

<a name="getFrame"></a>
~~~lua
virtual:getFrame() -> table
~~~
Gets the frame of the touch bar window

Parameters:
 * None

Returns:
 * a frame table with key-value pairs specifying the top left corner of the touch bar window and its width and height.

Notes:
 * A frame table is a table with at least `x`, `y`, `h` and `w` key-value pairs which specify the coordinates on the computer screen of the window and its width (w) and height(h).
 * This allows you to get the frame so that you can include its height and width in calculations - it does not allow you to change the size of the touch bar window itself.

- - -

<a name="hide"></a>
~~~lua
virtual:hide([duration]) -> touchbarObject
~~~
Display the touch bar window with an optional fade-out delay.

Parameters:
 * `duration` - an optional number, default 0.0, specifying the fade-out time for the touch bar window.

Returns:
 * the touchbarObject

Notes:
 * This method does nothing if the window is already hidden.
 * The value used in the sample code referenced in the module header is 0.1.

- - -

<a name="image"></a>
~~~lua
virtual:image() -> hs.image object | nil
~~~
Returns an image of the current contents of the virtual touchbar, or nil if the virtual touchbar is not currently being updated.

Parameters:
 * None

Returns:
 * an `hs.image` object of the current contents of the virtual touchbar, or nil if the virtual touchbar is not currently being updated.

Notes:
 * By default, the virtual touchbar is only receiving upates when it is visible on the screen -- [hs._asm.undocumented.touchbar.virtual:show](#show). If you wish to take a snapshot of the virtual touchbar but do not want it to be visible on the screen, you must invoke [hs._asm.undocumented.touchbar.virtual:streaming(true)](#streaming) before using this method.
   * Note that it may take a second or two after invoking [hs._asm.undocumented.touchbar.virtual:streaming(true)](#streaming) before the first image can be made, so you should check that the return value is not `nil` before using the image; you can use something like the following:
       
         myTouchbar = require("hs._asm.undocumented.touchbar").viritual.new():streaming(true)
         hs.timer.waitUntil(function() return myTouchbar:image() end, function()
            -- whatever you need now that images can be captured
         end)

   * Once streaming has been enabled and the first image is received, subsequent image requests will continue to succeed until streaming is stopped with [hs._asm.undocumented.touchbar.virtual:streaming(false)](#streaming) or [hs._asm.undocumented.touchbar.virtual:hide()](#hide).

- - -

<a name="inactiveAlpha"></a>
~~~lua
virtual:inactiveAlpha([alpha]) -> number | touchbarObject
~~~
Get or set the alpha value for the touch bar window when the mouse is not hovering over it.

Parameters:
 * alpha - an optional number between 0.0 and 1.0 inclusive specifying the alpha value for the touch bar window when the mouse is not over it.  Defaults to 0.5.

Returns:
 * if a value is provided, returns the touchbarObject; otherwise returns the current value

- - -

<a name="isVisible"></a>
~~~lua
virtual:isVisible() -> boolean
~~~
Returns a boolean indicating whether or not the touch bar window is current visible.

Parameters:
 * None

Returns:
 * a boolean specifying whether the touch bar window is visible (true) or not (false).

- - -

<a name="movable"></a>
~~~lua
virtual:movable([state]) -> boolean | touchbarObject
~~~
Get or set whether or not the touch bar window is movable by clicking on it and holding down the mouse button while moving the mouse.

Parameters:
 * `state` - an optional boolean which specifies whether the touch bar window is movable (true) or not (false).  Default false.

Returns:
 * if an argument is provided, returns the touchbarObject; otherwise returns the current value.

Notes:
 * While the touch bar is movable, actions which require moving the mouse while clicking on the touch bar are not accessible.
 * See also [hs._asm.undocumented.touchbar.virtual:acceptsMouseEvents](#acceptsMouseEvents).

- - -

<a name="setCallback"></a>
~~~lua
virtual:setCallback(fn | nil) -> touchbarObject
~~~
Sets the callback function for the touch bar window.

Parameters:
 * `fn` - a function to set as the callback for the touch bar window, or nil to remove the existing callback function.

Returns:
 * the touchbarObject

Notes:
 * The function should expect 2 arguments and return none.  The arguments will be one of the following:

   * obj, "didEnter" - indicates that the mouse pointer has entered the window containing the touch bar
     * `obj`     - the touchbarObject the callback is for
     * `message` - the message to the callback, in this case "didEnter"

   * obj, "didExit" - indicates that the mouse pointer has exited the window containing the touch bar
     * `obj`     - the touchbarObject the callback is for
     * `message` - the message to the callback, in this case "didEnter"

- - -

<a name="show"></a>
~~~lua
virtual:show([duration]) -> touchbarObject
~~~
Display the touch bar window with an optional fade-in delay.

Parameters:
 * `duration` - an optional number, default 0.0, specifying the fade-in time for the touch bar window.

Returns:
 * the touchbarObject

Notes:
 * This method does nothing if the window is already visible.

- - -
<a name="streaming"></a>
~~~lua
virtual:streaming(state) -> touchbarObject
~~~
Enable or disable updates to the virtual touchbar.

Parameters:
 * `state` - a boolean specifying whether or not the virtual touchbar window should be updated to reflect the current contents of the touchbar.

Returns:
 * the touchbarObject

Notes:
 * This method is invoked automatically with `true` when [hs._asm.undocumented.touchbar.virtual:show](#show) is invoked and with `false` when [hs._asm.undocumented.touchbar.virtual:hide](#hide) is invoked.
 * In order for [hs._asm.undocumented.touchbar.virtual:image](#image) to be able to capture a snapshot of the touchbar, the virtual touchbar must be currently receiving updates; this method will allow you to enable the updates even if the virtual touchbar is not currently visible on the screen (for example, if you have a physical touchbar on your laptop and do not wish to clutter the display with a duplicate of what you already posses).

- - -

<a name="toggle"></a>
~~~lua
virtual:toggle([duration]) -> touchbarObject
~~~
Toggle's the visibility of the touch bar window.

Parameters:
 * `duration` - an optional number, default 0.0, specifying the fade-in/out time when changing the visibility of the touch bar window.

Returns:
 * the touchbarObject

- - -

<a name="topLeft"></a>
~~~lua
virtual:topLeft([point]) -> table | touchbarObject
~~~
Get or set the top-left of the touch bar window.

Parameters:
 * `point` - an optional table specifying where the top left of the touch bar window should be moved to.

Returns:
 * if a value is provided, returns the touchbarObject; otherwise returns the current value.

Notes:
 * A point table is a table with at least `x` and `y` key-value pairs which specify the coordinates on the computer screen where the window should be moved to.  Hammerspoon considers the upper left corner of the primary screen to be { x = 0.0, y = 0.0 }.

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
