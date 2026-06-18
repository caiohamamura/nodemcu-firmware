cmake_minimum_required(VERSION 3.24)
if (NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/xtensa-esp8266-toolchain.cmake)
endif()
project(nodemcu-firmware-app LANGUAGES C ASM)

message(STATUS "Lua Version: ${LUA}")

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/parse_flags.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/parse_user_modules_h.cmake)

if (NOT SDK_DIR)
    include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/download_prune_sdk.cmake)
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/configure_buildinfo_h.cmake")
message(STATUS "SELECTED_MODULES: ${SELECTED_MODULES}")

include_directories(
    include
    ${CMAKE_CURRENT_SOURCE_DIR}/../sdk-overrides/include
    ${SDK_DIR}/include
)

add_compile_definitions(
    LWIP_OPEN_SRC
)

 # Base modules (always needed)
add_subdirectory(platform)
add_subdirectory(uzlib)
if (LUA EQUAL 53)
    add_subdirectory(lua53)
else()
    add_subdirectory(lua)
    endif()
add_subdirectory(libc)
add_subdirectory(driver)
add_subdirectory(fatfs)
add_subdirectory(esp-gdbstub)
add_subdirectory(lwip)
add_subdirectory(crypto)
add_subdirectory(user)
add_subdirectory(modules)
add_subdirectory(mbedtls)
add_subdirectory(net)
add_subdirectory(pm)
add_subdirectory(smart)
add_subdirectory(spiffs)



set(LINKLIBRARIES 
user
crypto
driver
platform
libc
lua
lwip
smart
spiffs
fatfs
pm
esp-gdbstub
net
mbedtls
modules
smart
uzlib
)

# Optional modules
set(OPTIONAL_MODULES 
    coap
    dht
    http
    mqtt
    pcm
    sjson
    tsl2561
    websocket
)

# Add optional modules selected
foreach(optional_module IN LISTS OPTIONAL_MODULES)
    if (optional_module IN_LIST SELECTED_MODULES)
        message(STATUS "Selected optional module: ${optional_module}")
        add_subdirectory(${optional_module})
        LIST(APPEND OPTIONAL_MODULES_SELECTED ${optional_module})
    endif()
endforeach()

# Lib optional modules
if ("u8g2" IN_LIST SELECTED_MODULES)
    add_subdirectory(u8g2lib)
    LIST(APPEND OPTIONAL_MODULES_SELECTED u8g2lib)
endif()

if ("ucg" IN_LIST SELECTED_MODULES)
    add_subdirectory(ucglib)
    LIST(APPEND OPTIONAL_MODULES_SELECTED ucglib)
endif()


# Add undefined symbols linker flags -u <MODULE_NAME>_module_selected
list(TRANSFORM SELECTED_MODULES TOUPPER OUTPUT_VARIABLE SELECTED_MODULES_UPPER)
list(TRANSFORM SELECTED_MODULES_UPPER APPEND "_module_selected" OUTPUT_VARIABLE UNDEFINED_SYMBOLS)
list(TRANSFORM UNDEFINED_SYMBOLS PREPEND "SHELL:-u " OUTPUT_VARIABLE UNDEFINED_SYMBOLS_FLAGS)


# Create firmware elf
set(EXECUTABLE_NAME app.elf)

add_executable(${EXECUTABLE_NAME} nodemcu-vscode-newlib.c)

# Allow using -Wl,--start-group end-group in linker command
set(CMAKE_C_LINK_GROUP_USING_rescan_SUPPORTED TRUE)
set(CMAKE_C_LINK_GROUP_USING_rescan
    "LINKER:--start-group"
    "LINKER:--end-group"
  )

set(ALL_LINK_LIBRARIES ${LINKLIBRARIES} ${OPTIONAL_MODULES_SELECTED})
list(JOIN ALL_LINK_LIBRARIES "," ALL_LINK_LIBRARIES)
target_link_libraries(${EXECUTABLE_NAME} PRIVATE
    $<LINK_GROUP:rescan,-lmain,${ALL_LINK_LIBRARIES}>)


# SDK libraries
set(SDK_LIBRARIES
    gcc
    hal
    phy
    pp
    net80211
    smartconfig
    wpa
    wpa2
    crypto
    wps
    c
    m
)
# Add -l to force linking to libraries from -L path
list(TRANSFORM SDK_LIBRARIES PREPEND "-l")
list(JOIN SDK_LIBRARIES " " SDK_LIBRARIES)
target_link_libraries(${EXECUTABLE_NAME} PRIVATE
    $<LINK_GROUP:rescan,${SDK_LIBRARIES}>
)


target_link_options(${EXECUTABLE_NAME} PRIVATE
    -Wl,--gc-sections
    -Wl,-Map=mapfile
    -nostdlib
    "-T${CMAKE_CURRENT_SOURCE_DIR}/../ld/nodemcu.ld"
    "-Wl,@${CMAKE_CURRENT_SOURCE_DIR}/../ld/defsym.rom"
    -Wl,--no-check-sections
    -Wl,-static
    ${UNDEFINED_SYMBOLS_FLAGS}
) 

target_link_directories(${EXECUTABLE_NAME} PRIVATE
    ${SDK_DIR}/lib
    ${SDK_DIR}/ld
)


