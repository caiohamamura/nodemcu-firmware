file(GLOB LIB_SRCS "*.c")

add_library(websocket STATIC ${LIB_SRCS})
