if (NOT ${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows") 
    message(WARNING "This script is only needed for Windows")
endif()

find_program(NINJA_FOUND ninja)

if(NINJA_FOUND)
    message(STATUS "Ninja is already available!")
    return()
endif()

set(GITHUB_NINJA "https://github.com/ninja-build/ninja")
set(NINJA_PATH ${CMAKE_CURRENT_LIST_DIR}/../tools/toolchains/ninja)
set(NINJA_VER "1.13.1")
set(NINJA_URL "${GITHUB_NINJA}/releases/download/v${NINJA_VER}/ninja-win.zip" )
set(NINJA_HASH "SHA256=26A40FA8595694DEC2FAD4911E62D29E10525D2133C9A4230B66397774AE25BF")


if (NOT EXISTS "${NINJA_PATH}/ninja.exe")
    set(FETCHCONTENT_QUIET FALSE)
    FetchContent_Declare(
        ninja_build
        URL ${NINJA_URL}
        URL_HASH ${NINJA_HASH}
        SOURCE_DIR ${NINJA_PATH}
        DOWNLOAD_NO_EXTRACT FALSE
    )

    message(STATUS "Downloading ninja ${NINJA_URL}...")
    
    # Download and extract the toolchain
    FetchContent_MakeAvailable(ninja_build)

    set(CMAKE_PROGRAM_PATH ${CMAKE_PROGRAM_PATH} ${NINJA_PATH})
else()
    message(STATUS "Ninja already downloaded")
    set(CMAKE_PROGRAM_PATH ${CMAKE_PROGRAM_PATH} ${NINJA_PATH})
endif()