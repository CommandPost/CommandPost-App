hs.text.http
============

Perform HTTP requests with hs.text objects

This submodule is a subset of the `hs.http` module modified to return `hs.text` objects for the response body of http requests. For http methods which allow submitting a body (e.g. POST), `hs.text` object may be used instead of lua strings as well.

### Usage
~~~lua
http = require("hs.text").http
~~~

### Contents

##### Module Functions
* <a href="#asyncGet">http.asyncGet(url, headers, callback)</a>
* <a href="#asyncPost">http.asyncPost(url, data, headers, callback)</a>
* <a href="#doAsyncRequest">http.doAsyncRequest(url, method, data, headers, callback, [cachePolicy])</a>
* <a href="#doRequest">http.doRequest(url, method, [data, headers, cachePolicy]) -> int, textObject, table</a>
* <a href="#get">http.get(url, headers) -> int, textObject, table</a>
* <a href="#post">http.post(url, data, headers) -> int, textObject, table</a>

- - -

### Module Functions

<a name="asyncGet"></a>
~~~lua
http.asyncGet(url, headers, callback)
~~~
Sends an HTTP GET request asynchronously

Parameters:
 * `url`      - A string containing the URL to retrieve
 * `headers`  - A table containing string keys and values representing the request headers, or nil to add no headers
 * `callback` - A function to be called when the request succeeds or fails. The function will be passed three parameters:
  * A number containing the HTTP response status
  * A textObject containing the response body
  * A table containing the response headers

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.

 * If the request fails, the callback function's first parameter will be negative and the second parameter will contain an error message. The third parameter will be nil

- - -

<a name="asyncPost"></a>
~~~lua
http.asyncPost(url, data, headers, callback)
~~~
Sends an HTTP POST request asynchronously

Parameters:
 * `url`      - A string containing the URL to submit to
 * `data`     - A string or hs.text object containing the request body, or nil to send no body
 * `headers`  - A table containing string keys and values representing the request headers, or nil to add no headers
 * `callback` - A function to be called when the request succeeds or fails. The function will be passed three parameters:
  * A number containing the HTTP response status
  * A textObject containing the response body
  * A table containing the response headers

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.

 * If the request fails, the callback function's first parameter will be negative and the second parameter will contain an error message. The third parameter will be nil

- - -

<a name="doAsyncRequest"></a>
~~~lua
http.doAsyncRequest(url, method, data, headers, callback, [cachePolicy])
~~~
Creates an HTTP request and executes it asynchronously

Parameters:
 * `url`         - A string containing the URL
 * `method`      - A string containing the HTTP method to use (e.g. "GET", "POST", etc)
 * `data`        - A string or `hs.text` object containing the request body, or nil to send no body
 * `headers`     - A table containing string keys and values representing request header keys and values, or nil to add no headers
 * `callback`    - A function to called when the response is received. The function should accept three arguments:
  * `code`    - A number containing the HTTP response code
  * `body`    - An `hs.text` object containing the body of the response
  * `headers` - A table containing the HTTP headers of the response
 * `cachePolicy` - An optional string containing the cache policy ("protocolCachePolicy", "ignoreLocalCache", "ignoreLocalAndRemoteCache", "returnCacheOrLoad", "returnCacheDontLoad" or "reloadRevalidatingCache"). Defaults to `protocolCachePolicy`.

Returns:
 * None

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.
 * If the Content-Type response header begins `text/` then the response body return value is a UTF8 string. Any other content type passes the response body, unaltered, as a stream of bytes.

- - -

<a name="doRequest"></a>
~~~lua
http.doRequest(url, method, [data, headers, cachePolicy]) -> int, textObject, table
~~~
Creates an HTTP request and executes it synchronously

Parameters:
 * `url`         - A string containing the URL
 * `method`      - A string containing the HTTP method to use (e.g. "GET", "POST", etc)
 * `data`        - An optional string or `hs.text` object containing the data to POST to the URL, or nil to send no data
 * `headers`     - An optional table of string keys and values used as headers for the request, or nil to add no headers
 * `cachePolicy` - An optional string containing the cache policy ("protocolCachePolicy", "ignoreLocalCache", "ignoreLocalAndRemoteCache", "returnCacheOrLoad", "returnCacheDontLoad" or "reloadRevalidatingCache"). Defaults to `protocolCachePolicy`.

Returns:
 * A number containing the HTTP response status code
 * An `hs.text` object containing the response body
 * A table containing the response headers

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.

 * This function is synchronous and will therefore block all Lua execution until it completes. You are encouraged to use the asynchronous functions.
 * If you attempt to connect to a local Hammerspoon server created with `hs.httpserver`, then Hammerspoon will block until the connection times out (60 seconds), return a failed result due to the timeout, and then the `hs.httpserver` callback function will be invoked (so any side effects of the function will occur, but it's results will be lost).  Use [hs.text.http.doAsyncRequest](#doAsyncRequest) to avoid this.
 * If the Content-Type response header begins `text/` then the response body return value is a UTF8 string. Any other content type passes the response body, unaltered, as a stream of bytes.

- - -

<a name="get"></a>
~~~lua
http.get(url, headers) -> int, textObject, table
~~~
Sends an HTTP GET request to a URL

Parameters
 * `url`     - A string containing the URL to retrieve
 * `headers` - A table containing string keys and values representing the request headers, or nil to add no headers

Returns:
 * A number containing the HTTP response status
 * A textObject containing the response body
 * A table containing the response headers

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.

 * This function is synchronous and will therefore block all other Lua execution while the request is in progress, you are encouraged to use the asynchronous functions
 * If you attempt to connect to a local Hammerspoon server created with `hs.httpserver`, then Hammerspoon will block until the connection times out (60 seconds), return a failed result due to the timeout, and then the `hs.httpserver` callback function will be invoked (so any side effects of the function will occur, but it's results will be lost).  Use [hs.text.http.asyncGet](#asyncGet) to avoid this.

- - -

<a name="post"></a>
~~~lua
http.post(url, data, headers) -> int, textObject, table
~~~
Sends an HTTP POST request to a URL

Parameters
 * `url`     - A string containing the URL to submit to
 * `data`    - A string or hs.text object containing the request body, or nil to send no body
 * `headers` - A table containing string keys and values representing the request headers, or nil to add no headers

Returns:
 * A number containing the HTTP response status
 * A textObject containing the response body
 * A table containing the response headers

Notes:
 * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.

 * This function is synchronous and will therefore block all other Lua execution while the request is in progress, you are encouraged to use the asynchronous functions
 * If you attempt to connect to a local Hammerspoon server created with `hs.httpserver`, then Hammerspoon will block until the connection times out (60 seconds), return a failed result due to the timeout, and then the `hs.httpserver` callback function will be invoked (so any side effects of the function will occur, but it's results will be lost).  Use [hs.text.http.asyncPost](#asyncPost) to avoid this.

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
