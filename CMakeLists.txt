cmake_minimum_required(VERSION 3.10)

project(luac_cross C)

set(SOURCES
    app/lua/lapi.c
    app/lua/lauxlib.c
    app/lua/lbaselib.c
    app/lua/lcode.c
    app/lua/ldblib.c
    app/lua/ldebug.c
    app/lua/ldo.c
    app/lua/ldump.c
    app/lua/lfunc.c
    app/lua/lgc.c
    app/lua/linit.c
    app/lua/llex.c
    app/lua/lmathlib.c
    app/lua/lmem.c
    app/lua/lnodemcu.c
    app/lua/loadlib.c
    app/lua/lobject.c
    app/lua/lopcodes.c
    app/lua/lparser.c
    app/lua/lstate.c
    app/lua/lstring.c
    app/lua/lstrlib.c
    app/lua/ltable.c
    app/lua/ltablib.c
    app/lua/ltm.c
    app/lua/luac_cross/lflashimg.c
    app/lua/luac_cross/liolib.c
    app/lua/luac_cross/loslib.c
    app/lua/luac_cross/luac.c
    app/lua/luac_cross/print.c
    app/lua/lundump.c
    app/lua/lvm.c
    app/lua/lzio.c
    app/modules/bit.c
    app/modules/color_utils.c
    app/modules/sjson.c
    app/modules/pipe.c
    app/modules/struct.c
    app/sjson/jsonsl.c
    app/uzlib/crc32.c
    app/uzlib/uzlib_deflate.c
)


# --- Executable ---
add_executable(luac.cross ${SOURCES} ${HEADERS})

# --- Include Directories ---
target_include_directories(luac.cross PRIVATE
    app/lua
    app/libc
    app/include
    app/uzlib
    app
)

# --- Preprocessor Definitions ---
target_compile_definitions(luac.cross PRIVATE
    LUA_CROSS_COMPILER
    LUA_OPTIMIZE_MEMORY=2
    _CRT_SECURE_NO_WARNINGS
    _CONSOLE
    WIN32
)

# --- Config-specific Options ---
target_compile_options(luac.cross PRIVATE $<$<CONFIG:Debug>:/MTd>)
target_compile_options(luac.cross PRIVATE $<$<CONFIG:Release>:/MT>)

target_compile_definitions(luac.cross PRIVATE
    $<$<CONFIG:Debug>:LUA_DEBUG_BUILD _DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)

# --- Linker Settings ---
target_link_libraries(luac.cross PRIVATE
    kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib
    shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib
)

install(TARGETS luac.cross
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)