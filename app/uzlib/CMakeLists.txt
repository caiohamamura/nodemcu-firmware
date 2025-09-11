file(GLOB LIB_SRCS "*.c")

add_library(uzlib STATIC ${LIB_SRCS})

target_include_directories(uzlib PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>    
)
