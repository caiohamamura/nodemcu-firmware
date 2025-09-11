set(LIBNAME lwip)
file(GLOB LIB_SRCS "*/*.c" "*/*/*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_compile_definitions(${LIBNAME} PRIVATE
    PBUF_RSV_FOR_WLAN
    EBUF_LWIP 
)

target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)