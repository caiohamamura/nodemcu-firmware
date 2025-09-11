set(LIBNAME ucglib)
file(GLOB LIB_SRCS "ucg/src/clib/*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_compile_definitions(${LIBNAME} PRIVATE
    USE_PIN_LIST
)

target_include_directories(${LIBNAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ucg/src/clib>
)

target_include_directories(platform PRIVATE
    $<TARGET_PROPERTY:ucglib,INTERFACE_INCLUDE_DIRECTORIES>
)
target_include_directories(modules PRIVATE
    $<TARGET_PROPERTY:ucglib,INTERFACE_INCLUDE_DIRECTORIES>
)