file(GLOB LIB_SRCS "*.c" "*.S")

add_library(esp-gdbstub STATIC ${LIB_SRCS})
