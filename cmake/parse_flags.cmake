# Set build type to Release if not set
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(LUA "51" CACHE STRING "Lua version to use (51 or 53)")

option(LUA_NUMBER_INTEGRAL "Use integer for lua numbers")
if (LUA_NUMBER_INTEGRAL)
    if (LUA STREQUAL "53")
        message(FATAL_ERROR "LUA_NUMBER_INTEGRAL is not supported for Lua 5.3")
    endif()
    add_compile_definitions(LUA_NUMBER_INTEGRAL)
endif()

option(LUA_NUMBER_64BITS "Use 64-bit for lua numbers")
if (LUA_NUMBER_64BITS)
    if (LUA_NUMBER_INTEGRAL)
        message(FATAL_ERROR "LUA_NUMBER_64BITS and LUA_NUMBER_INTEGRAL are mutually exclusive")
    endif()
    if(NOT LUA STREQUAL "53")
        message(FATAL_ERROR "LUA_NUMBER_64BITS is only supported for Lua 5.3")
    endif()
    add_compile_definitions(LUA_NUMBER_64BITS)
endif()

# Silence warnings for Release configuration
if (CMAKE_C_COMPILER_ID MATCHES "MSVC")
    add_compile_options($<$<CONFIG:Release>:/W0>)
else()
    add_compile_options(
        $<$<CONFIG:Release>:-w>
    )
endif()

set(RUNTIME_DESTINATION "bin" CACHE STRING "Destination for runtime files")