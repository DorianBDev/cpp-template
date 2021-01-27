# Read version file
file(READ "${PROJECT_SOURCE_DIR}/VERSION" VERSION_FILE_CONTENT)
string(TIMESTAMP CURRENT_DATE "%Y-%m-%d")

# Create the list
STRING(REGEX REPLACE "\n" ";" VERSION_FILE_CONTENT "${VERSION_FILE_CONTENT}")

# Clear empty list entries
STRING(REGEX REPLACE ";;" ";" VERSION_FILE_CONTENT "${VERSION_FILE_CONTENT}")

# Remove lines that start with a '#'
foreach(LINE ${VERSION_FILE_CONTENT})
    if("${LINE}" MATCHES "^(#.*|\\n)")
        list(REMOVE_ITEM VERSION_FILE_CONTENT "${LINE}")
        continue()
    endif()
endforeach()

# Read the project version
list(GET VERSION_FILE_CONTENT 0 PROJECT_VERSION)

# Read the project version release date
list(GET VERSION_FILE_CONTENT 1 PROJECT_RELEASE_DATE)

# Print information
if("${PROJECT_NAME}" STREQUAL "")
    # If the project name is not set, then we are in the build process
    execute_process(COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --red --bold
            "======================================="
            "\t Project version: ${PROJECT_VERSION}"
            "\t Release date:    ${PROJECT_RELEASE_DATE}"
            "\t Build date:      ${CURRENT_DATE}"
            "\t OS:              ${CMAKE_SYSTEM_NAME}"
            "\t Configuration:   ${CONFIGURATION}"
            "=======================================")
else()
    # Otherwise we are in the CMakeLists load/reload process
    message(STATUS "Project version: ${PROJECT_VERSION}")
    message(STATUS "Release date: ${PROJECT_RELEASE_DATE}")
endif()

# Format version to Qt compatible one
string(REPLACE "alpha" "0" PROJECT_VERSION_STR "${PROJECT_VERSION}")
string(REPLACE "beta" "1" PROJECT_VERSION_STR "${PROJECT_VERSION_STR}")
string(REPLACE "rc" "2" PROJECT_VERSION_STR "${PROJECT_VERSION_STR}")

# Set if the version is a nightly
if("${PROJECT_VERSION}" MATCHES "(-)")
    set(VERSION_TYPE "nightly")
else()
    set(VERSION_TYPE "release")
    set(PROJECT_VERSION_STR "${PROJECT_VERSION_STR}-3.0")
endif()

# Set the platform variable
if("${CMAKE_SYSTEM_NAME}" MATCHES "(Windows)")
    set(PLATFORM "windows")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "(Linux)")
    set(PLATFORM "linux")
elseif("${CMAKE_SYSTEM_NAME}" MATCHES "(Darwin)")
    set(PLATFORM "macos")
endif()

# Configure version file
configure_file("${PROJECT_SOURCE_DIR}/etc/config/Version.config" "${PROJECT_SOURCE_DIR}/src/Version.h")

# Configure doxyfile
configure_file("${PROJECT_SOURCE_DIR}/doc/config/Doxyfile.config" "${PROJECT_SOURCE_DIR}/doc/config/DoxyFile")

# If the release date is "Unreleased" then take the current date (build date)
if(PROJECT_RELEASE_DATE MATCHES "Unreleased")
    set(PROJECT_RELEASE_DATE "${CURRENT_DATE}")
endif()