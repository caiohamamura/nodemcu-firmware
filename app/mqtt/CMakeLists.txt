file(GLOB LIB_SRCS "*.c")

add_library(mqtt STATIC ${LIB_SRCS})
