include(FetchContent)

set(SDK_FILE_VERSION "v3.0.0")
set(SDK_URL "https://github.com/espressif/ESP8266_NONOS_SDK/archive/release/${SDK_FILE_VERSION}.zip")
set(URL_HASH "SHA256=ca222303db3960780c6e442b619db25eb1f34c32bf9dd60f287c510336f4430b")
set(SDK_VER "3.0-e4434aa")
set(SDK_BASE_EXTRACT_DIR "${CMAKE_CURRENT_LIST_DIR}/../sdk")
set(SDK_DIR "${SDK_BASE_EXTRACT_DIR}/esp_iot_sdk_v${SDK_VER}")
set(SDK_DOWNLOAD_FILE "${CMAKE_BINARY_DIR}/sdk.zip")


if(NOT EXISTS ${SDK_DIR})
    message(STATUS "Downloading SDK...")
    file(DOWNLOAD ${SDK_URL} ${SDK_DOWNLOAD_FILE} SHOW_PROGRESS EXPECTED_HASH ${URL_HASH})
endif()

# Create the tools directory if it doesn't exist
file(MAKE_DIRECTORY "${SDK_BASE_EXTRACT_DIR}")

set(ZIP_BASE_DIRECTORY "ESP8266_NONOS_SDK-release-${SDK_FILE_VERSION}")
if(NOT EXISTS "${SDK_DIR}/lib")
    message(STATUS "Extracting SDK...")
    file(ARCHIVE_EXTRACT 
                INPUT ${SDK_DOWNLOAD_FILE}
                DESTINATION ${SDK_BASE_EXTRACT_DIR}
                PATTERNS "${ZIP_BASE_DIRECTORY}/lib" "${ZIP_BASE_DIRECTORY}/ld/*.v6.ld" "${ZIP_BASE_DIRECTORY}/include" "${ZIP_BASE_DIRECTORY}/bin/esp_init_data_default_v05.bin"
    )
    file(GLOB OUTPUT_DIR LIST_DIRECTORIES true RELATIVE ${SDK_BASE_EXTRACT_DIR} "${SDK_BASE_EXTRACT_DIR}/ESP*")
    
    file(RENAME "${SDK_BASE_EXTRACT_DIR}/${OUTPUT_DIR}" "${SDK_DIR}")
endif()


set(LOCAL_AR "${TOOLCHAIN_EXTRACT_DIR}/bin/xtensa-lx106-elf-ar")
if (NOT EXISTS "${SDK_BASE_EXTRACT_DIR}/.pruned-${SDK_VER}")
    message(STATUS "PRUNE libmain.a")
    message(STATUS "PRUNE libc.a")
    execute_process(
        COMMAND ${LOCAL_AR} d ${SDK_DIR}/lib/libmain.a time.o
        COMMAND ${LOCAL_AR} d ${SDK_DIR}/lib/libc.a lib_a-time.o
        ERROR_VARIABLE  ERROR_OUT
    )
    if(ERROR_OUT)
        message(FATAL_ERROR ${ERROR_OUT})
    endif()
    file(TOUCH "${SDK_BASE_EXTRACT_DIR}/.pruned-${SDK_VER}")
endif()
