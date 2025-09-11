set(LIBNAME u8g2lib)
file(GLOB LIB_SRCS "*.c" "u8g2/src/clib/*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})


target_include_directories(${LIBNAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/u8g2/src/clib>
)

target_compile_definitions(${LIBNAME} PRIVATE
    U8X8_USE_PINS
    U8G2_USE_LARGE_FONTS
    U8X8_WITH_USER_PTR
)

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)

target_include_directories(platform PRIVATE
    $<TARGET_PROPERTY:u8g2lib,INTERFACE_INCLUDE_DIRECTORIES>
)
target_include_directories(modules PRIVATE
    $<TARGET_PROPERTY:u8g2lib,INTERFACE_INCLUDE_DIRECTORIES>
)