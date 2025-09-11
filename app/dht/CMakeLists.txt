set(LIBNAME dht)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)

target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
)

target_include_directories(${LIBNAME} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)