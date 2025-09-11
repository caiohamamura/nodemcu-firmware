set(LIBNAME platform)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:spiffs,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:user,INTERFACE_INCLUDE_DIRECTORIES>
)

# If we compile with u8g2 we get implicit declarations:
# os_delay_us
# os_memcpy
target_compile_options(${LIBNAME} PRIVATE
    -Wno-error=implicit-function-declaration
    -Wimplicit
    -std=gnu11
)
