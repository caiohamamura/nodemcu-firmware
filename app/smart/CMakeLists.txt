set(LIBNAME smart)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

# Multiple functions are not declared:
# os_timer_arm
# os_timer_setfn
# os_timer_disarm
target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)
