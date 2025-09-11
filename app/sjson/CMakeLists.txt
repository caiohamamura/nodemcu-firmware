include(
    memcompat.h 
    json_config.h
)

file(GLOB LIB_SRCS "*.c")

add_library(sjson STATIC ${LIB_SRCS})
