set(LIBNAME http)
file(GLOB LIB_SRCS "*.c")

add_library(${LIBNAME} STATIC ${LIB_SRCS})

if(CMAKE_HOST_WIN32)
    target_compile_definitions(${LIBNAME} PRIVATE
       strcasestr=strstr
    )
endif()

