# HTTP Module
| Since  | Origin / Contributor  | Maintainer  | Source  |
| :----- | :-------------------- | :---------- | :------ |
| 2016-01-15 | [esphttpclient](https://github.com/Caerbannog/esphttpclient) / [Vowstar](https://github.com/vowstar) | [Vowstar](https://github.com/vowstar) | [http.c](../../app/modules/http.c)|

Basic HTTP *client* module that provides an interface to do GET/POST/PUT/DELETE over HTTP(S), as well as customized requests. Due to the memory constraints on ESP8266, the buffered request methods (`http.get`, `http.post`, ...) accumulate the whole response body in RAM, so the supported page/body size is limited by available memory; attempting to receive pages larger than this will fail. For large responses use the **streaming** variants [`http.get_stream`](#httpget_stream) / [`http.post_stream`](#httppost_stream), which deliver the body to your callback chunk-by-chunk and keep RAM use flat regardless of the total body size. (Alternatively, [`net.createConnection()`](net.md#netcreateconnection) can stream raw data.)

!!! attention

    It is **not** possible to execute concurrent HTTP requests using this module.

Each request method takes a callback which is invoked when the response has been received from the server. The first argument is the status code, which is either a regular HTTP status code, or -1 to denote a DNS, connection or out-of-memory failure, or a timeout (currently at 60 seconds).

For each operation it is possible to provide custom HTTP headers or override standard headers. By default the `Host` header is deduced from the URL and `User-Agent` is `ESP8266`. Note, however, that the `Connection` header *can not* be overridden! It is always set to `close`.

HTTP redirects (HTTP status 300-308) are followed automatically up to a limit of 20 to avoid the dreaded redirect loops.

When the callback is invoked, it is passed the HTTP status code, the body as it was received, and a table of the response headers. All the header names have been lower cased
to make it easy to access. If there are multiple headers of the same name, then only the last one is returned.

#### Streaming callback

The `*_stream` methods instead invoke the callback *repeatedly* as the body
arrives, with the signature `callback(status, chunk, headers, done)`:

- `status` — the HTTP status code (or `-1` on a DNS/connection/out-of-memory/timeout error). Always a number, on every call.
- `chunk` — the next piece of the response body, as a string (possibly empty `""`); `nil` when there is no body for this call (e.g. on an error).
- `headers` — the lower-cased response-header table, passed on the **first** invocation only; `nil` on every later call.
- `done` — `false` while more of the body may still arrive, `true` on the final invocation. After the `done == true` call the callback is not invoked again.

Concatenate the `chunk`s as they arrive and act once `done` is `true`. The whole body is never held in firmware RAM, so streamed responses are bounded by `SSL_BUFFER_SIZE` (for HTTPS, per-record) rather than by the total body size.

**SSL/TLS support**

!!! attention

    Secure (`https`) connections come with quite a few limitations.  Please see
    the warnings in the [tls module](tls.md)'s documentation.

## http.delete()

Executes a HTTP DELETE request. Note that concurrent requests are not supported.

#### Syntax
`http.delete(url, headers, body, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `body` The body to post; must already be encoded in the appropriate format, but may be empty
- `callback` The callback function to be invoked when the response has been received or an error occurred; it is invoked with the arguments `status_code`, `body` and `headers`. In case of an error `status_code` is set to -1.

#### Returns
`nil`

#### Example
```lua
http.delete('http://httpbin.org/delete',
  "",
  "",
  function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)
```

## http.get()

Executes a HTTP GET request. Note that concurrent requests are not supported.

#### Syntax
`http.get(url, headers, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `callback` The callback function to be invoked when the response has been received or an error occurred; it is invoked with the arguments `status_code`, `body` and `headers`. In case of an error `status_code` is set to -1.

#### Returns
`nil`

#### Example
```lua
http.get("http://httpbin.org/ip", nil, function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)
```

## http.get_stream()

Executes a HTTP GET request, delivering the response body to the callback in
chunks instead of buffering it whole. Use this for responses too large to fit in
RAM. Note that concurrent requests are not supported.

#### Syntax
`http.get_stream(url, headers, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `callback` The streaming callback, invoked repeatedly as the body arrives with the arguments `status`, `chunk`, `headers`, `done` (see [Streaming callback](#streaming-callback) above). On an error `status` is `-1` and `done` is `true`.

#### Returns
`nil`

#### Example
```lua
-- Stream a large body without holding it all in RAM (here: just count bytes).
local total = 0
http.get_stream("https://httpbin.org/bytes/100000", nil,
  function(status, chunk, headers, done)
    if chunk then total = total + #chunk end
    if done then
      if status < 0 then
        print("HTTP request failed")
      else
        print("status", status, "body bytes", total)
      end
    end
  end)
```

## http.post()

Executes a HTTP POST request. Note that concurrent requests are not supported.

#### Syntax
`http.post(url, headers, body, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `body` The body to post; must already be encoded in the appropriate format, but may be empty
- `callback` The callback function to be invoked when the response has been received or an error occurred; it is invoked with the arguments `status_code`, `body` and `headers`. In case of an error `status_code` is set to -1.

#### Returns
`nil`

#### Example
```lua
http.post('http://httpbin.org/post',
  'Content-Type: application/json\r\n',
  '{"hello":"world"}',
  function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)
```

## http.post_stream()

Executes a HTTP POST request, delivering the response body to the callback in
chunks instead of buffering it whole (the streaming counterpart of
[`http.post`](#httppost)). Note that concurrent requests are not supported.

#### Syntax
`http.post_stream(url, headers, body, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `body` The body to post; must already be encoded in the appropriate format, but may be empty
- `callback` The streaming callback, invoked repeatedly as the body arrives with the arguments `status`, `chunk`, `headers`, `done` (see [Streaming callback](#streaming-callback) above). On an error `status` is `-1` and `done` is `true`.

#### Returns
`nil`

#### Example
```lua
local total = 0
http.post_stream('https://httpbin.org/post',
  'Content-Type: application/json\r\n',
  '{"hello":"world"}',
  function(status, chunk, headers, done)
    if chunk then total = total + #chunk end
    if done then print("status", status, "body bytes", total) end
  end)
```

## http.put()

Executes a HTTP PUT request. Note that concurrent requests are not supported.

#### Syntax
`http.put(url, headers, body, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `body` The body to post; must already be encoded in the appropriate format, but may be empty
- `callback` The callback function to be invoked when the response has been received or an error occurred; it is invoked with the arguments `status_code`, `body` and `headers`. In case of an error `status_code` is set to -1.

#### Returns
`nil`

#### Example
```lua
http.put('http://httpbin.org/put',
  'Content-Type: text/plain\r\n',
  'Hello!\nStay a while, and listen...\n',
  function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)
```

## http.request()

Execute a custom HTTP request for any HTTP method. Note that concurrent requests are not supported.

#### Syntax
`http.request(url, method, headers, body, callback)`

#### Parameters
- `url` The URL to fetch, including the `http://` or `https://` prefix
- `method` The HTTP method to use, e.g. "GET", "HEAD", "OPTIONS" etc
- `headers` Optional additional headers to append, *including \r\n*; may be `nil`
- `body` The body to post; must already be encoded in the appropriate format, but may be empty
- `callback` The callback function to be invoked when the response has been received or an error occurred; it is invoked with the arguments `status_code`, `body` and `headers`. In case of an error `status_code` is set to -1.

#### Returns
`nil`

#### Example
```lua
http.request("http://httpbin.org", "HEAD", "", "",
  function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)
```
