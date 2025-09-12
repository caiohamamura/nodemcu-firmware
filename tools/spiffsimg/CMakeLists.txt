cmake_minimum_required(VERSION 3.10)

# Check if is root configure
if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    project(spiffsimg C)
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(APP_DIR ../../app)
set(SOURCES
    main.c
    ${APP_DIR}/spiffs/spiffs_cache.c
    ${APP_DIR}/spiffs/spiffs_check.c
    ${APP_DIR}/spiffs/spiffs_gc.c
    ${APP_DIR}/spiffs/spiffs_hydrogen.c
    ${APP_DIR}/spiffs/spiffs_nucleus.c
)

set(BINARY_NAME "spiffsimg")

# --- Executable ---
add_executable(${BINARY_NAME} ${SOURCES} ${HEADERS})


target_compile_definitions(${BINARY_NAME} PRIVATE
        NODEMCU_SPIFFS_NO_INCLUDE
        dbg_printf=printf
)

# If not MSVC compiler add pixbuf.c
if (CMAKE_C_COMPILER_ID MATCHES "MSVC")
    target_include_directories(${BINARY_NAME} PRIVATE
        windows_include
    )
endif()


# --- Include Directories ---
target_include_directories(${BINARY_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${APP_DIR}/spiffs
    ${APP_DIR}/include
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${BINARY_NAME} PRIVATE
        LUA_CROSS_COMPILER
        LUA_DEBUG_BUILD
        DEVELOPMENT_TOOLS
        DDEVELOPMENT_USE_GDB
    )
endif()

if(MSVC)
    add_definitions(/FI"spiffs_typedefs.h")
else()
    # GCC or Clang
    add_definitions(-include spiffs_typedefs.h)
endif()


install(TARGETS ${BINARY_NAME}
)
