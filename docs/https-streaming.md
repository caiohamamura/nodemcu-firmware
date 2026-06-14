# HTTPS Streaming and TLS RAM Optimizations

## Background

ESP8266 boots with ~42 KB free heap. A TLS handshake alone consumes ~26 KB:

| Point | Free heap |
|---|---|
| Before handshake | ~39.5 KB |
| After handshake | ~13–16 KB |
| During body receive | ~7–12 KB (tightest) |
| After connection close | ~38 KB |

This left no room to buffer large response bodies (e.g. CloudFront ~102 KB, fragmented heap can't fit even 8 KB contiguous post-handshake).

## Changes

### 1. `MBEDTLS_SSL_OUT_CONTENT_LEN` 4096 → 2048 (`app/include/user_mbedtls.h`)

The client only ever sends small TLS records (ClientHello+SNI, key exchange, Finished, HTTP request) — all well under 2 KB. Halving the outbound buffer frees 2 KB across the entire TLS session, including the cert-parsing peak of the handshake. This was the margin that allowed larger cert chains (CloudFront, Google) to complete the handshake without OOM (`E:M 544`).

`MBEDTLS_SSL_IN_CONTENT_LEN` stays at 16384 (`SSL_BUFFER_SIZE`); the server sends full-sized TLS records.

### 2. Response body streaming (`app/http/httpclient.c`)

`BUFFER_SIZE_MAX` (now 0x0800 = 2 KB) is allocated **after** the handshake (in `http_connect_callback`, not at request start) and holds only the response headers up to `\r\n\r\n`. Once the header terminator is found, that buffer is freed and the body is never accumulated — each TLS delivery (~1460 B = TCP_MSS) is forwarded directly to the Lua callback. Peak RAM during streaming: one segment, not the whole body.

Redirects (3xx with `Location:` header) are not streamed — they need the full header block available in the disconnect handler.

### 3. Heap trace macro (`app/http/httpclient.h`)

Define `HTTPCLIENT_HEAP_TRACE` at compile time to re-enable the 4-point heap measurement. Output goes through `NODE_ERR` (not `os_printf`, which is suppressed in NodeMCU).

## Updated Lua callback contract

**Existing Lua code must be updated.** The `http.get` / `http.post` / `http.request` callbacks now receive **4 arguments** instead of 3:

```lua
-- OLD (breaks for large responses):
http.get(url, nil, function(status, body, headers)
  print(body)
end)

-- NEW (required):
http.get(url, nil, function(status, chunk, headers, done)
  -- headers: table on first call, nil on subsequent chunks
  -- done: true on the final (empty) call; connection is closed after this
  if chunk and #chunk > 0 then
    -- accumulate or process chunk
  end
  if done then
    -- request complete
  end
end)
```

For small responses the callback is still invoked once with the full body and `done=true`. For large responses it is invoked multiple times:

1. First call: `headers` = parsed headers table, `chunk` = initial body bytes, `done=false`
2. Middle calls: `headers=nil`, `chunk` = next segment, `done=false`
3. Final call: `headers=nil`, `chunk=""` (empty), `done=true`

Recommended drain pattern (from `tests/NTest_http.lua`):

```lua
local total = 0
http.get(url, nil, function(status, chunk, headers, done)
  if type(chunk) == "string" then total = total + #chunk end
  if done then print("done, bytes=" .. total) end
end)
```
