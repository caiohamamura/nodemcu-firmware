file(GLOB LIB_SRCS "*.c")

add_library(libc STATIC ${LIB_SRCS})

target_include_directories(libc PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)