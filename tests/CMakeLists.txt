#
# Enable testing
#
enable_testing()

#
# Include doctest
#
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/lib/")

#
# The tests source files
#
file(GLOB_RECURSE TEST_SRC_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" LIST_DIRECTORIES false
    "src/*.c"
    "src/*.cpp"
    "src/*.h"
    "src/*.hpp"
)

#
# Include directories
#
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../src")

#
# Defines groups (to respect folders hierarchy)
#
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src" PREFIX "src" FILES ${TEST_SRC_FILES})

#
# MacOS linker error solution. See: https://github.com/onqtam/doctest/issues/126 and https://github.com/onqtam/doctest/issues/356.
#
add_definitions(-DDOCTEST_CONFIG_USE_STD_HEADERS)

#
# Link
#
add_executable(${PROJECT_NAME}Tests ${TEST_SRC_FILES})
target_link_libraries(${PROJECT_NAME}Tests ${PROJECT_NAME}Core)

#
# Output specifications
#
set_target_properties(${PROJECT_NAME}Tests
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "lib"
    LIBRARY_OUTPUT_DIRECTORY "lib"
    RUNTIME_OUTPUT_DIRECTORY "bin"
)

#
# Copy res folder contents to bin folder
#
add_custom_command(TARGET ${PROJECT_NAME}Tests POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/res $<TARGET_FILE_DIR:${PROJECT_NAME}Tests>/res
    DEPENDS ${CMAKE_SOURCE_DIR}/res)
	
#
# Copy res folder contents to tests folder
#
add_custom_command(TARGET ${PROJECT_NAME}Tests POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/res ${CMAKE_CURRENT_BINARY_DIR}/tests/res
    DEPENDS ${CMAKE_SOURCE_DIR}/res)

#
# Copy test files to bin folder
#
add_custom_command(
        TARGET ${PROJECT_NAME}Tests POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tests/res/ $<TARGET_FILE_DIR:${PROJECT_NAME}Tests>/tests_res/)
		
#
# Copy test files to tests folder
#
add_custom_command(
        TARGET ${PROJECT_NAME}Tests POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tests/res/ ${CMAKE_CURRENT_BINARY_DIR}/tests/tests_res/)
		
#
# Link doctest to ctest
#
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/doctest.cmake)
doctest_discover_tests(${PROJECT_NAME}Tests)