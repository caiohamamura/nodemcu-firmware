set(HOST_C_COMPILER ${CMAKE_C_COMPILER})
set(HOST_C_COMPILER_TARGET "${CMAKE_C_COMPILER_TARGET}")
include(${CMAKE_CURRENT_LIST_DIR}/xtensa-esp8266-toolchain.cmake)

message(STATUS "CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")

execute_process(
    COMMAND ${CMAKE_C_COMPILER} -E -dM "${CMAKE_CURRENT_LIST_DIR}/../app/include/user_config.h"
    OUTPUT_VARIABLE USER_CONFIG_CONTENT
) 

# Split content into lines
string(REPLACE "\n" ";" USER_CONFIG_CONTENT "${USER_CONFIG_CONTENT}")

# Process each line
list(TRANSFORM USER_CONFIG_CONTENT REPLACE ".*define *([^ ;]+).*" "\\1" OUTPUT_VARIABLE USER_CONFIG_CONTENT)
set(CMAKE_C_COMPILER ${HOST_C_COMPILER})
# Restore the host compiler target. The toolchain include above leaks
# CMAKE_C_COMPILER_TARGET (xtensa-lx106-elf) and -D_C_TYPES_H_ into this
# directory scope, which is the host luac.cross build. A Clang host would then
# emit --target=xtensa-lx106-elf and abort ("unknown target triple"); GCC just
# ignores it. Undo both so the host tool builds with the native toolchain.
set(CMAKE_C_COMPILER_TARGET "${HOST_C_COMPILER_TARGET}")
remove_definitions(-D_C_TYPES_H_)
set(USER_CONFIG ${USER_CONFIG_CONTENT})