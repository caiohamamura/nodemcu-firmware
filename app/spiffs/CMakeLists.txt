set(LIBNAME spiffs)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)
