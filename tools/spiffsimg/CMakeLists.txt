cmake_minimum_required(VERSION 3.10)

project(spiffsimg C)


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

# --- Executable ---
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})


target_compile_definitions(${PROJECT_NAME} PRIVATE
        NODEMCU_SPIFFS_NO_INCLUDE
        dbg_printf=printf
)

# If not MSVC compiler add pixbuf.c
if (CMAKE_C_COMPILER_ID MATCHES "MSVC")
    target_include_directories(${PROJECT_NAME} PRIVATE
        windows_include
    )
endif()


# --- Include Directories ---
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${APP_DIR}/spiffs
    ${APP_DIR}/include
)


target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
)

if(MSVC)
    add_definitions(/FI"spiffs_typedefs.h")
else()
    # GCC or Clang
    add_definitions(-include spiffs_typedefs.h)
endif()


install(TARGETS ${PROJECT_NAME}
)
