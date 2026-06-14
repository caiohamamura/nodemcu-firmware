/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Martin d'Allens <martin.dallens@gmail.com> wrote this file. As long as you retain
 * this notice you can do whatever you want with this stuff. If we meet some day,
 * and you think this stuff is worth it, you can buy me a beer in return.
 * ----------------------------------------------------------------------------
 */

#ifndef __HTTPCLIENT_H__
#define __HTTPCLIENT_H__

static const char log_prefix[] = "HTTP client: ";

#if defined(DEVELOP_VERSION)
  #define HTTPCLIENT_DEBUG_ON
#endif
#if defined(HTTPCLIENT_DEBUG_ON)
  #define HTTPCLIENT_DEBUG(format, ...) dbg_printf("%s"format"\n", log_prefix, ##__VA_ARGS__)
#else
  #define HTTPCLIENT_DEBUG(...)
#endif
#if defined(NODE_ERROR)
  #define HTTPCLIENT_ERR(format, ...) NODE_ERR("%s"format"\n", log_prefix, ##__VA_ARGS__)
#else
  #define HTTPCLIENT_ERR(...)
#endif
/*
 * Define HTTPCLIENT_HEAP_TRACE to print free heap at four points of a request
 * (before/after handshake, after first received byte, after close). Useful for
 * sizing the TLS buffers on RAM-constrained targets; off by default.
 */
#if defined(HTTPCLIENT_HEAP_TRACE)
  #define HTTPCLIENT_HEAP(label) NODE_ERR("HTTPHEAP " label "=%d\n", system_get_free_heap_size())
#else
  #define HTTPCLIENT_HEAP(label)
#endif

#if defined(USES_SDK_BEFORE_V140)
  #define espconn_send espconn_sent
  #define espconn_secure_send espconn_secure_sent
#endif

/*
 * In case of TCP or DNS error the callback is called with this status.
 */
#define HTTP_STATUS_GENERIC_ERROR  (-1)

/*
 * Size of http responses that will cause an error.
 */
/* With body streaming this buffer only holds the response headers until the
 * "\r\n\r\n" terminator, so a small value keeps the post-handshake allocation
 * (made while the heap is at its tightest) cheap. Header blocks larger than this
 * are rejected with a clean error. */
#define BUFFER_SIZE_MAX            (0x0800)

/*
 * Timeout of http request.
 */
#define HTTP_REQUEST_TIMEOUT_MS    (60000)

/*
 * "full_response" is a string containing all response headers and the response body.
 * "response_body and "http_status" are extracted from "full_response" for convenience.
 *
 * A successful request corresponds to an HTTP status code of 200 (OK).
 * More info at http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
 */
/*
 * The callback is normally invoked once, with the complete response body and
 * `done` set to true.
 *
 * For responses larger than BUFFER_SIZE_MAX the client switches to streaming
 * mode rather than failing with "Response too long": the callback is then
 * invoked multiple times. The first invocation carries the parsed headers (via
 * full_response_p) plus the initial body bytes; subsequent invocations carry
 * further body chunks with full_response_p == NULL; the final invocation has an
 * empty body and `done` set to true. This bounds peak RAM to roughly
 * BUFFER_SIZE_MAX plus one TCP segment instead of the whole body.
 */
typedef void (* http_callback_t)(char * response_body, int http_status, char ** full_response_p, int body_size, bool done);

/*
 * Call this function to skip URL parsing if the arguments are already in separate variables.
 * http_raw_request      — accumulate full response (old behaviour, errors on > BUFFER_SIZE_MAX)
 * http_raw_request_stream — stream body chunks; callback receives multiple calls until done=true
 */
void ICACHE_FLASH_ATTR http_raw_request(const char * hostname, int port, bool secure, const char * method, const char * path, const char * headers, const char * post_data, http_callback_t callback_handle, int redirect_follow_count);
void ICACHE_FLASH_ATTR http_raw_request_stream(const char * hostname, int port, bool secure, const char * method, const char * path, const char * headers, const char * post_data, http_callback_t callback_handle, int redirect_follow_count);

/*
 * Request data from URL use custom method.
 */
void ICACHE_FLASH_ATTR http_request(const char * url, const char * method, const char * headers, const char * post_data, http_callback_t callback_handle, int redirect_follow_count);
void ICACHE_FLASH_ATTR http_request_stream(const char * url, const char * method, const char * headers, const char * post_data, http_callback_t callback_handle, int redirect_follow_count);

void ICACHE_FLASH_ATTR http_post(const char * url, const char * headers, const char * post_data, http_callback_t callback_handle);
void ICACHE_FLASH_ATTR http_get(const char * url, const char * headers, http_callback_t callback_handle);
void ICACHE_FLASH_ATTR http_delete(const char * url, const char * headers, const char * post_data, http_callback_t callback_handle);
void ICACHE_FLASH_ATTR http_put(const char * url, const char * headers, const char * post_data, http_callback_t callback_handle);

/* Streaming variants — callback receives cb(chunk, status, headers_or_nil, body_size, done) multiple times. */
void ICACHE_FLASH_ATTR http_get_stream(const char * url, const char * headers, http_callback_t callback_handle);
void ICACHE_FLASH_ATTR http_post_stream(const char * url, const char * headers, const char * post_data, http_callback_t callback_handle);
void ICACHE_FLASH_ATTR http_put_stream(const char * url, const char * headers, const char * post_data, http_callback_t callback_handle);

/*
 * Output on the UART.
 */
void http_callback_example(char * response, int http_status, char * full_response);

#endif // __HTTPCLIENT_H__
