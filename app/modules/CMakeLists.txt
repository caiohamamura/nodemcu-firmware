set(LIBNAME modules)
list(TRANSFORM SELECTED_MODULES APPEND ".c" OUTPUT_VARIABLE SOURCES)

file(GLOB LIB_SRCS "*.c")


add_library(${LIBNAME} STATIC ${LIB_SRCS})

# Add previous directory, modules will search for module_name/header.
target_include_directories(${LIBNAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)

target_compile_options(${LIBNAME} PRIVATE
    -Wimplicit
    -std=gnu11
)

