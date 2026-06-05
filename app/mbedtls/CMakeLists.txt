set(LIBNAME mbedtls)
file(GLOB LIB_SRCS "*/*.c")
list(FILTER LIB_SRCS EXCLUDE REGEX ".*/library/psa_.*\\.c$")
list(FILTER LIB_SRCS EXCLUDE REGEX ".*/library/mps_.*\\.c$")
list(FILTER LIB_SRCS EXCLUDE REGEX ".*/library/ssl_tls13_keys\\.c$")

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
