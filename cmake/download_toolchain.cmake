include(FetchContent)

STRING(TOLOWER ${CMAKE_HOST_SYSTEM_NAME} CMAKE_HOST_SYSTEM_NAME_LOWER)
set(WIN_SYSTEMS 
    windows 
    msys
)
if(CMAKE_HOST_SYSTEM_NAME_LOWER IN_LIST WIN_SYSTEMS)
    set(TOOLCHAIN "xtensa-lx106-elf-win32-1.22.0-88-gde0bdc1-4.8.5")
    set(TOOLCHAIN_URL "https://dl.espressif.com/dl/${TOOLCHAIN}.tar.gz")
    set(TOOLCHAIN_EXTRACT_DIR "${CMAKE_SOURCE_DIR}/tools/toolchains/esp8266-${TOOLCHAIN}")
    set(TOOLCHAIN_NAME "esp8266-toolchain-windows")
    set(URL_HASH "SHA256=83B166B7A3C4023CF65CF1C3424FEC07F0C6EC10956485D86CC22197495F1C33")
else()
    set(TOOLCHAIN "linux-x86_64-20190731.0")
    set(TOOLCHAIN_URL "https://github.com/jmattsson/esp-toolchains/releases/download/${TOOLCHAIN}/toolchain-esp8266-${TOOLCHAIN}.tar.xz")
    set(TOOLCHAIN_EXTRACT_DIR "${CMAKE_SOURCE_DIR}/tools/toolchains/esp8266-${TOOLCHAIN}")
    set(TOOLCHAIN_NAME "esp8266-toolchain-linux")
    set(URL_HASH "SHA256=8C09804CFEDC203A006F571E7163EFA89004CD9057DA5CD4A4734D15A5CF7FB4")
endif()

if(EXISTS ${TOOLCHAIN_EXTRACT_DIR}/bin)
    message(STATUS "Toolchain already downloaded")
    return()
endif()

# Create the tools directory if it doesn't exist
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/tools/toolchains")

# Configure FetchContent
set(FETCHCONTENT_QUIET FALSE)
FetchContent_Declare(
    ${TOOLCHAIN_NAME}
    URL ${TOOLCHAIN_URL}
    URL_HASH ${URL_HASH}
    SOURCE_DIR ${TOOLCHAIN_EXTRACT_DIR}
    DOWNLOAD_NO_EXTRACT FALSE  # Allow extraction
)


message(STATUS "Downloading toolchain ${TOOLCHAIN_URL}...")
FetchContent_MakeAvailable(${TOOLCHAIN_NAME})

# List the contents of the toolchain directory
file(GLOB toolchain_files "${TOOLCHAIN_EXTRACT_DIR}/bin/*")
message(STATUS "Toolchain contents:")
foreach(file ${toolchain_files})
    message(STATUS "  ${file}")
endforeach()