set(LIBNAME pm)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)

# os_timer_disarm is not declared!
target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)