# xtensa-esp8266-toolchain.cmake
# CMake toolchain file for ESP8266 Xtensa cross-compilation

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR xtensa)

# Set the toolchain path
set(EXT "")
set(CMAKE_C_FLAGS_INIT "-g -ffunction-sections -std=gnu11 -fno-jump-tables -fdata-sections -fpack-struct=4 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals")
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR CMAKE_HOST_SYSTEM_NAME STREQUAL "MSYS")
    set(TOOLCHAIN_PATH "${CMAKE_CURRENT_LIST_DIR}/../tools/toolchains/esp8266-xtensa-lx106-elf-win32-1.22.0-88-gde0bdc1-4.8.5/bin")
    set(EXT ".exe")
    add_compile_definitions(
        stricmp=strcasecmp
        WIN32
    )
else()
    set(TOOLCHAIN_PATH "${CMAKE_CURRENT_LIST_DIR}/../tools/toolchains/esp8266-linux-x86_64-20190731.0/bin")
endif()

# Set the cross-compiler prefix
set(TOOLCHAIN_PREFIX "xtensa-lx106-elf-")

# Set compilers
set(CMAKE_C_COMPILER "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}gcc${EXT}")
set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")

# Set other tools
set(CMAKE_AR "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}ar${EXT}")
set(CMAKE_RANLIB "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}ranlib${EXT}")
set(CMAKE_STRIP "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}strip${EXT}")
set(CMAKE_OBJCOPY "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}objcopy${EXT}")
set(CMAKE_OBJDUMP "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}objdump${EXT}")
set(CMAKE_SIZE "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}size${EXT}")
set(CMAKE_NM "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}nm${EXT}")

# Set find root path modes
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)


# Prevent the SDK's c_types.h from being included from anywhere, by predefining its include-guard.
add_compile_definitions(_C_TYPES_H_)

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS_INIT "")

# Set the target triple
set(CMAKE_C_COMPILER_TARGET "xtensa-lx106-elf")

# Skip compiler tests (cross-compilation)
set(CMAKE_C_COMPILER_WORKS TRUE)

# Don't run the linker on compiler check
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)