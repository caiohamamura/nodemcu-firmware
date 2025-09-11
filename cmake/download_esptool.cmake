set(GITHUB_ESPTOOL "https://github.com/espressif/esptool")
set(ESPTOOL_PATH ${CMAKE_CURRENT_LIST_DIR}/../tools/toolchains/esptool.py)
set(ESPTOOL_VER "2.6")
set(ESPTOOL_URL "${GITHUB_ESPTOOL}/archive/refs/tags/v${ESPTOOL_VER}.tar.gz" )
set(ESPTOOL_HASH "SHA256=51EBE169CADE538C986E92EB65562B8FF3A1293BAF14B9AD977DF888061ED78E")
set(ESPTOOL_DOWNLOAD "${CMAKE_BINARY_DIR}/esptool-${ESPTOOL_VER}.tar.gz")

if (NOT EXISTS "${ESPTOOL_PATH}")
    message(STATUS "Downloading esptool from ${ESPTOOL_URL}")
    file(DOWNLOAD ${ESPTOOL_URL} "${CMAKE_BINARY_DIR}/esptool-${ESPTOOL_VER}.tar.gz" SHOW_PROGRESS EXPECTED_HASH ${ESPTOOL_HASH})
else()
    message(STATUS "esptool already downloaded")
    return()
endif()

file(ARCHIVE_EXTRACT 
            INPUT ${ESPTOOL_DOWNLOAD}
            DESTINATION ${CMAKE_BINARY_DIR}
            PATTERNS "esptool-${ESPTOOL_VER}/esptool.py"
)
file(RENAME ${CMAKE_BINARY_DIR}/esptool-${ESPTOOL_VER}/esptool.py ${ESPTOOL_PATH})
