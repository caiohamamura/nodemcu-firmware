cmake_minimum_required(VERSION 3.24)

# Check if is root configure
if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    project(luac_cross C)
    include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/parse_flags.cmake)
endif()

if(NOT CMAKE_BUILD_TYPE) 
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(USER_CONFIG "")
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/parse_user_config_h.cmake)
set(BINARY_NAME "luac.cross")
if("LUA_NUMBER_INTEGRAL" IN_LIST USER_CONFIG OR LUA_NUMBER_INTEGRAL)
    set(BINARY_NAME "${BINARY_NAME}.int")
endif()

set(LUA_DIR "lua")
set(LUAC_CROSS_DIR "luac_cross")
if (LUA STREQUAL "53")
    set(LUA_DIR "lua53")
    set(LUAC_CROSS_DIR "host")    
endif()

SET(APP_DIR "${CMAKE_CURRENT_LIST_DIR}/../../app")
set(SOURCES
    # Luac
    ${APP_DIR}/${LUA_DIR}/${LUAC_CROSS_DIR}/luac.c
    ${APP_DIR}/${LUA_DIR}/${LUAC_CROSS_DIR}/liolib.c
    ${APP_DIR}/${LUA_DIR}/${LUAC_CROSS_DIR}/loslib.c
    
    # Lua
    ${APP_DIR}/${LUA_DIR}/lapi.c
    ${APP_DIR}/${LUA_DIR}/lauxlib.c
    ${APP_DIR}/${LUA_DIR}/lbaselib.c
    ${APP_DIR}/${LUA_DIR}/lcode.c
    ${APP_DIR}/${LUA_DIR}/ldblib.c
    ${APP_DIR}/${LUA_DIR}/ldebug.c
    ${APP_DIR}/${LUA_DIR}/ldo.c
    ${APP_DIR}/${LUA_DIR}/ldump.c
    ${APP_DIR}/${LUA_DIR}/lfunc.c
    ${APP_DIR}/${LUA_DIR}/lgc.c
    ${APP_DIR}/${LUA_DIR}/linit.c
    ${APP_DIR}/${LUA_DIR}/llex.c
    ${APP_DIR}/${LUA_DIR}/lmathlib.c
    ${APP_DIR}/${LUA_DIR}/lmem.c
    ${APP_DIR}/${LUA_DIR}/loadlib.c
    ${APP_DIR}/${LUA_DIR}/lnodemcu.c
    ${APP_DIR}/${LUA_DIR}/lobject.c
    ${APP_DIR}/${LUA_DIR}/lopcodes.c
    ${APP_DIR}/${LUA_DIR}/lparser.c
    ${APP_DIR}/${LUA_DIR}/lstate.c
    ${APP_DIR}/${LUA_DIR}/lstring.c
    ${APP_DIR}/${LUA_DIR}/lstrlib.c
    ${APP_DIR}/${LUA_DIR}/ltable.c
    ${APP_DIR}/${LUA_DIR}/ltablib.c
    ${APP_DIR}/${LUA_DIR}/ltm.c
    ${APP_DIR}/${LUA_DIR}/lundump.c
    ${APP_DIR}/${LUA_DIR}/lvm.c
    ${APP_DIR}/${LUA_DIR}/lzio.c
    
    # SJson
    ${APP_DIR}/sjson/jsonsl.c
    
    # UZlib
    ${APP_DIR}/uzlib/uzlib_deflate.c
    ${APP_DIR}/uzlib/crc32.c
    
    # Modules
    ${APP_DIR}/modules/struct.c
    ${APP_DIR}/modules/bit.c
    ${APP_DIR}/modules/color_utils.c
    ${APP_DIR}/modules/sjson.c
    ${APP_DIR}/modules/pipe.c    
    ${APP_DIR}/modules/pixbuf.c

)


if (LUA STREQUAL "53")
    list(APPEND SOURCES 
        ${APP_DIR}/${LUA_DIR}/lcorolib.c
        ${APP_DIR}/${LUA_DIR}/lctype.c
        ${APP_DIR}/${LUA_DIR}/lutf8lib.c
    )
else()
    list(APPEND SOURCES 
        ${APP_DIR}/${LUA_DIR}/${LUAC_CROSS_DIR}/lflashimg.c
        ${APP_DIR}/${LUA_DIR}/${LUAC_CROSS_DIR}/print.c
    )

    set(COMPILE_DEFS 
        LUA_CROSS_COMPILER
    )
endif()

if (NOT CMAKE_C_COMPILER_ID MATCHES "MSVC")
    set(LINK_LIBRARIES 
        -lm
    )
endif()

# --- Executable ---
add_executable(${BINARY_NAME} ${SOURCES})


# --- Include Directories ---
target_include_directories(${BINARY_NAME} PRIVATE
    ${APP_DIR}/${LUA_DIR}
    ${APP_DIR}/libc
    ${APP_DIR}/include
    ${APP_DIR}/uzlib
    ${APP_DIR}
)

target_compile_definitions(${BINARY_NAME} PRIVATE
    ${COMPILE_DEFS}
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${BINARY_NAME} PRIVATE
        LUA_CROSS_COMPILER
        LUA_DEBUG_BUILD
        DEVELOPMENT_TOOLS
        DDEVELOPMENT_USE_GDB
    )
endif()

target_link_libraries(${BINARY_NAME} PRIVATE
    ${LINK_LIBRARIES}
)


install(TARGETS ${BINARY_NAME})
