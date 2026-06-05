cmake_minimum_required(VERSION 3.24)
project(nodemcu_firmware C)

# Parse flags LUA LUA_NUMBER_*
include(${CMAKE_SOURCE_DIR}/cmake/parse_flags.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/download_toolchain.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/download_prune_sdk.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/download_esptool.cmake)

include(ProcessorCount)
ProcessorCount(CORE_COUNT)
set(PARALLEL_FLAG)
if(CORE_COUNT GREATER 1)
    set(PARALLEL_FLAG "-j${CORE_COUNT}")
endif()

#####################
# luac_cross
#####################
add_subdirectory(tools/luac_cross)

#######################
# spiffsimg
#######################
add_subdirectory(tools/spiffsimg)

######################
# Configure firmware building
######################
# Set Ninja when generator is Visual Studio
if(CMAKE_GENERATOR MATCHES "^Visual Studio")
    include(${CMAKE_SOURCE_DIR}/cmake/download_ninja.cmake)
    set(CMAKE_GENERATOR Ninja)
endif()

include(ExternalProject)

message(STATUS "Cmake generator is ${CMAKE_GENERATOR}")

set(VERBOSE_FLAGS "")
if(CMAKE_VERBOSE_MAKEFILE)
    set(VERBOSE_FLAGS "-v")
endif()

find_package(Python3 COMPONENTS Interpreter REQUIRED)
set(NODEELF2IMAGE_PYTHON ${Python3_EXECUTABLE})

set(CURRENT_BINARY_DIR ${CMAKE_BINARY_DIR}/firmware_build)
ExternalProject_Add(firmware
    SOURCE_DIR      ${CMAKE_SOURCE_DIR}/app
    BINARY_DIR      ${CURRENT_BINARY_DIR}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    CMAKE_ARGS
        -DCMAKE_PROGRAM_PATH=${CMAKE_PROGRAM_PATH}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cmake/xtensa-esp8266-toolchain.cmake
        -DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}
    BUILD_COMMAND   ${CMAKE_COMMAND} --build ${CURRENT_BINARY_DIR} ${BUILD_CONFIG} ${PARALLEL_FLAG} ${VERBOSE_FLAGS}
    INSTALL_COMMAND ${CMAKE_COMMAND} --install ${CURRENT_BINARY_DIR}
)

add_custom_command(
    OUTPUT ${CMAKE_SOURCE_DIR}/bin/0x00000.bin
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/bin
    COMMAND ${NODEELF2IMAGE_PYTHON} tools/toolchains/esptool.py elf2image --flash_mode dio --flash_freq 40m "${CURRENT_BINARY_DIR}/app.elf" -o "${CMAKE_SOURCE_DIR}/bin/"
    DEPENDS firmware ${CURRENT_BINARY_DIR}/app.elf
    COMMENT "Running firmware transformer"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(
    build_all ALL
    DEPENDS ${CMAKE_SOURCE_DIR}/bin/0x00000.bin
)


