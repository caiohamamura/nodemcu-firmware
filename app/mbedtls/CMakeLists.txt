set(LIBNAME mbedtls)
file(GLOB LIB_SRCS "*/*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
)

target_compile_definitions(${LIBNAME} PRIVATE
    MBEDTLS_USER_CONFIG_FILE=\"user_mbedtls.h\"
)

# if host is windows
if(CMAKE_HOST_WIN32)
    target_compile_options(${LIBNAME} PRIVATE
       -Wno-error=implicit-function-declaration
    )
endif()