# Paths
set(BUILDINFO_H ${CMAKE_CURRENT_LIST_DIR}/../app/include/buildinfo.h)

# Git info
execute_process(
    COMMAND git rev-parse HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE COMMIT_ID
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND git rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(REGEX REPLACE "[/\\\\]+" "_" BRANCH "${BRANCH}")

execute_process(
    COMMAND git describe --tags --long
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE RELEASE
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(REGEX REPLACE "(.*)-([0-9]+)-.*" "\\1 +\\2" RELEASE "${RELEASE}")
string(REGEX REPLACE " \\+0$" "" RELEASE "${RELEASE}")

execute_process(
    COMMAND git show --quiet --date=format-local:%Y%m%d%H%M --format=%cd HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE RELEASE_DTS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(TIMESTAMP BUILD_DATE "%Y-%m-%d %H:%M")

option(USER_PROLOG "User prolog" "")
if (NOT USER_PROLOG)
    set(USER_PROLOG "User prolog" "")
endif()

list(TRANSFORM SELECTED_MODULES TOLOWER OUTPUT_VARIABLE MODULES)

configure_file(
    ${BUILDINFO_H}.in
    ${BUILDINFO_H}
    @ONLY
)