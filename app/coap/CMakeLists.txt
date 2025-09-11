set(LIBNAME coap)
file(GLOB LIB_SRCS "*.c")

add_library(coap STATIC ${LIB_SRCS})

target_include_directories(coap PRIVATE
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
)

target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)