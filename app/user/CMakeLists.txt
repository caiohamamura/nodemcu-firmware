set(LIBNAME user)
file(GLOB LIB_SRCS "*.c")

add_compile_definitions(
    ESP_INIT_DATA_DEFAULT="${SDK_DIR}/bin/esp_init_data_default_v05.bin"
)

add_library(${LIBNAME} STATIC ${LIB_SRCS})

target_include_directories(${LIBNAME} PRIVATE
    $<TARGET_PROPERTY:lua,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:platform,INTERFACE_INCLUDE_DIRECTORIES>
)