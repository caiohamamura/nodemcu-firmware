set(LIBNAME net)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

# eagle_lwip_getif not declared!
target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)
