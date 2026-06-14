/******************************************************************************
 * HTTP module for NodeMCU
 * vowstar@gmail.com
 * 2015-12-29
*******************************************************************************/
#include <string.h>
#include <stdlib.h>
#include "module.h"
#include "lauxlib.h"
#include "platform.h"
#include "cpu_esp8266.h"
#include "http/httpclient.h"
#include <ctype.h>

#define HTTP_CB_SLOTS 2

static int http_cb_refs[HTTP_CB_SLOTS]      = { LUA_NOREF, LUA_NOREF };
static int http_stream_cb_refs[HTTP_CB_SLOTS] = { LUA_NOREF, LUA_NOREF };
static int http_next_buf_slot = 0;
static int http_next_str_slot = 0;

static void http_cb_impl( char * response, int http_status, char ** full_response_p, int body_size, bool done, int slot )
{
  const char *full_response = full_response_p ? *full_response_p : NULL;

#if defined(HTTPCLIENT_DEBUG_ON)
  dbg_printf( "http_status=%d done=%d body_size=%d slot=%d\n", http_status, (int)done, body_size, slot );
#endif

  if (http_cb_refs[slot] != LUA_NOREF)
  {
    lua_State *L = lua_getstate();

    lua_rawgeti(L, LUA_REGISTRYINDEX, http_cb_refs[slot]);

    lua_pushinteger(L, http_status);
    if ( http_status != HTTP_STATUS_GENERIC_ERROR && response)
    {
      lua_pushlstring(L, response, (size_t)body_size);
    }
    else
    {
      lua_pushnil(L);
    }

    if ( full_response != NULL )
    {
      lua_newtable(L);

      const char *p = full_response;

      while (*p && *p != '\n') {
        p++;
      }
      if (*p == '\n') {
        p++;
      }

      while (*p && *p != '\r' && *p != '\n') {
        const char *eol = p;
        while (*eol && *eol != '\r') {
          eol++;
        }

        const char *colon = p;
        while (*colon != ':' && colon < eol) {
          colon++;
        }

        if (*colon != ':') {
          break;
        }

        const char *value = colon + 1;
        while (*value == ' ') {
          value++;
        }

        luaL_Buffer b;
        luaL_buffinit(L, &b);
        while (p < colon) {
          luaL_addchar(&b, tolower((unsigned char) *p));
          p++;
        }
        luaL_pushresult(&b);

        lua_pushlstring(L, value, eol - value);
        lua_settable(L, -3);

        p = eol + 1;
        if (*p == '\n') {
          p++;
        }
      }
    }
    else
    {
      lua_pushnil(L);
    }

    lua_pushboolean(L, done);

    if (full_response_p && *full_response_p) {
      free(*full_response_p);
      *full_response_p = NULL;
    }

    if ( done )
    {
      luaL_unref(L, LUA_REGISTRYINDEX, http_cb_refs[slot]);
      http_cb_refs[slot] = LUA_NOREF;
    }

    luaL_pcallx(L, 4, 0);
  }
  else if (full_response_p && *full_response_p)
  {
    free(*full_response_p);
    *full_response_p = NULL;
  }
}

static void http_callback_0( char * r, int s, char ** f, int b, bool d ) { http_cb_impl(r, s, f, b, d, 0); }
static void http_callback_1( char * r, int s, char ** f, int b, bool d ) { http_cb_impl(r, s, f, b, d, 1); }

static http_callback_t http_buf_callbacks[] = { http_callback_0, http_callback_1 };

static http_callback_t alloc_buf_slot( lua_State *L, int lua_cb_index )
{
  int slot = http_next_buf_slot;
  http_next_buf_slot = 1 - http_next_buf_slot;

  if (http_cb_refs[slot] != LUA_NOREF)
  {
    luaL_unref(L, LUA_REGISTRYINDEX, http_cb_refs[slot]);
    http_cb_refs[slot] = LUA_NOREF;
  }

  if (lua_isfunction(L, lua_cb_index)) {
    lua_pushvalue(L, lua_cb_index);
    http_cb_refs[slot] = luaL_ref(L, LUA_REGISTRYINDEX);
  }

  return http_buf_callbacks[slot];
}

static void http_stream_cb_impl( char * response, int http_status, char ** full_response_p, int body_size, bool done, int slot )
{
  const char *full_response = full_response_p ? *full_response_p : NULL;

  if (http_stream_cb_refs[slot] != LUA_NOREF)
  {
    lua_State *L = lua_getstate();

    lua_rawgeti(L, LUA_REGISTRYINDEX, http_stream_cb_refs[slot]);

    lua_pushinteger(L, http_status);
    if ( http_status != HTTP_STATUS_GENERIC_ERROR && response)
      lua_pushlstring(L, response, (size_t)body_size);
    else
      lua_pushnil(L);

    if ( full_response != NULL )
    {
      lua_newtable(L);
      const char *p = full_response;
      while (*p && *p != '\n') p++;
      if (*p == '\n') p++;
      while (*p && *p != '\r' && *p != '\n') {
        const char *eol = p;
        while (*eol && *eol != '\r') eol++;
        const char *colon = p;
        while (*colon != ':' && colon < eol) colon++;
        if (*colon != ':') break;
        const char *value = colon + 1;
        while (*value == ' ') value++;
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        while (p < colon) { luaL_addchar(&b, tolower((unsigned char)*p)); p++; }
        luaL_pushresult(&b);
        lua_pushlstring(L, value, eol - value);
        lua_settable(L, -3);
        p = eol + 1;
        if (*p == '\n') p++;
      }
    }
    else
      lua_pushnil(L);

    lua_pushboolean(L, done);

    if (full_response_p && *full_response_p) {
      free(*full_response_p);
      *full_response_p = NULL;
    }

    if ( done ) {
      luaL_unref(L, LUA_REGISTRYINDEX, http_stream_cb_refs[slot]);
      http_stream_cb_refs[slot] = LUA_NOREF;
    }

    luaL_pcallx(L, 4, 0);
  }
  else if (full_response_p && *full_response_p)
  {
    free(*full_response_p);
    *full_response_p = NULL;
  }
}

static void http_stream_callback_0( char * r, int s, char ** f, int b, bool d ) { http_stream_cb_impl(r, s, f, b, d, 0); }
static void http_stream_callback_1( char * r, int s, char ** f, int b, bool d ) { http_stream_cb_impl(r, s, f, b, d, 1); }

static http_callback_t http_stream_callbacks[] = { http_stream_callback_0, http_stream_callback_1 };

static http_callback_t alloc_str_slot( lua_State *L, int lua_cb_index )
{
  int slot = http_next_str_slot;
  http_next_str_slot = 1 - http_next_str_slot;

  if (http_stream_cb_refs[slot] != LUA_NOREF)
  {
    luaL_unref(L, LUA_REGISTRYINDEX, http_stream_cb_refs[slot]);
    http_stream_cb_refs[slot] = LUA_NOREF;
  }

  if (lua_isfunction(L, lua_cb_index)) {
    lua_pushvalue(L, lua_cb_index);
    http_stream_cb_refs[slot] = luaL_ref(L, LUA_REGISTRYINDEX);
  }

  return http_stream_callbacks[slot];
}

// Lua: http.request( url, method, header, body, function(status, reponse) end )
static int http_lapi_request( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * method  = luaL_checklstring(L, 2, &length);
  const char * headers = NULL;
  const char * body    = NULL;

  if ((url == NULL) || (method == NULL))
  {
    return luaL_error( L, "wrong arg type" );
  }

  if (lua_isstring(L, 3))
  {
    headers = luaL_checklstring(L, 3, &length);
  }
  if (lua_isstring(L, 4))
  {
    body = luaL_checklstring(L, 4, &length);
  }

  http_callback_t cb = http_buf_callbacks[0];
  if (lua_isfunction(L, 5))
    cb = alloc_buf_slot(L, 5);

  http_request(url, method, headers, body, cb, 0);
  return 0;
}

// Lua: http.post( url, header, body, function(status, reponse) end )
static int http_lapi_post( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;
  const char * body    = NULL;

  if ((url == NULL))
  {
    return luaL_error( L, "wrong arg type" );
  }

  if (lua_isstring(L, 2))
  {
    headers = luaL_checklstring(L, 2, &length);
  }
  if (lua_isstring(L, 3))
  {
    body = luaL_checklstring(L, 3, &length);
  }

  http_callback_t cb = http_buf_callbacks[0];
  if (lua_isfunction(L, 4))
    cb = alloc_buf_slot(L, 4);

  http_post(url, headers, body, cb);
  return 0;
}

// Lua: http.put( url, header, body, function(status, reponse) end )
static int http_lapi_put( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;
  const char * body    = NULL;

  if ((url == NULL))
  {
    return luaL_error( L, "wrong arg type" );
  }

  if (lua_isstring(L, 2))
  {
    headers = luaL_checklstring(L, 2, &length);
  }
  if (lua_isstring(L, 3))
  {
    body = luaL_checklstring(L, 3, &length);
  }

  http_callback_t cb = http_buf_callbacks[0];
  if (lua_isfunction(L, 4))
    cb = alloc_buf_slot(L, 4);

  http_put(url, headers, body, cb);
  return 0;
}

// Lua: http.delete( url, header, body, function(status, reponse) end )
static int http_lapi_delete( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;
  const char * body    = NULL;

  if ((url == NULL))
  {
    return luaL_error( L, "wrong arg type" );
  }

  if (lua_isstring(L, 2))
  {
    headers = luaL_checklstring(L, 2, &length);
  }
  if (lua_isstring(L, 3))
  {
    body = luaL_checklstring(L, 3, &length);
  }

  http_callback_t cb = http_buf_callbacks[0];
  if (lua_isfunction(L, 4))
    cb = alloc_buf_slot(L, 4);

  http_delete(url, headers, body, cb);
  return 0;
}

// Lua: http.get( url, header, function(status, reponse) end )
static int http_lapi_get( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;

  if ((url == NULL))
  {
    return luaL_error( L, "wrong arg type" );
  }

  if (lua_isstring(L, 2))
  {
    headers = luaL_checklstring(L, 2, &length);
  }

  http_callback_t cb = http_buf_callbacks[0];
  if (lua_isfunction(L, 3))
    cb = alloc_buf_slot(L, 3);

  http_get(url, headers, cb);
  return 0;
}

// Lua: http.get_stream( url, header, function(status, chunk, headers, done) end )
static int http_lapi_get_stream( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;

  if (url == NULL)
    return luaL_error( L, "wrong arg type" );

  if (lua_isstring(L, 2))
    headers = luaL_checklstring(L, 2, &length);

  http_callback_t cb = http_stream_callbacks[0];
  if (lua_isfunction(L, 3))
    cb = alloc_str_slot(L, 3);

  http_get_stream(url, headers, cb);
  return 0;
}

// Lua: http.post_stream( url, header, body, function(status, chunk, headers, done) end )
static int http_lapi_post_stream( lua_State *L )
{
  int length;
  const char * url     = luaL_checklstring(L, 1, &length);
  const char * headers = NULL;
  const char * body    = NULL;

  if (url == NULL)
    return luaL_error( L, "wrong arg type" );

  if (lua_isstring(L, 2))
    headers = luaL_checklstring(L, 2, &length);
  if (lua_isstring(L, 3))
    body = luaL_checklstring(L, 3, &length);

  http_callback_t cb = http_stream_callbacks[0];
  if (lua_isfunction(L, 4))
    cb = alloc_str_slot(L, 4);

  http_post_stream(url, headers, body, cb);
  return 0;
}

// Module function map
LROT_BEGIN(http, NULL, 0)
  LROT_FUNCENTRY( request, http_lapi_request )
  LROT_FUNCENTRY( post, http_lapi_post )
  LROT_FUNCENTRY( put, http_lapi_put )
  LROT_FUNCENTRY( delete, http_lapi_delete )
  LROT_FUNCENTRY( get, http_lapi_get )
  LROT_FUNCENTRY( get_stream, http_lapi_get_stream )
  LROT_FUNCENTRY( post_stream, http_lapi_post_stream )

  LROT_NUMENTRY( OK, 0 )
  LROT_NUMENTRY( ERROR, HTTP_STATUS_GENERIC_ERROR )

LROT_END(http, NULL, 0)


NODEMCU_MODULE(HTTP, "http", http, NULL);
