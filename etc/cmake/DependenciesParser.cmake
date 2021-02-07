# Read dependencies file
file(READ "${PROJECT_SOURCE_DIR}/DEPENDENCIES" DEPENDENCIES_FILE_CONTENT)

# Create the list
STRING(REGEX REPLACE "\n" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Clear empty list entries
STRING(REGEX REPLACE ";;" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Remove lines that start with a '#'
foreach(LINE ${DEPENDENCIES_FILE_CONTENT})
    if("${LINE}" MATCHES "^(#.*|\\n)")
        list(REMOVE_ITEM DEPENDENCIES_FILE_CONTENT "${LINE}")
        continue()
    endif()
endforeach()

# Clear empty list entries
STRING(REGEX REPLACE ";;" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Parse dependencies
foreach(LINE ${DEPENDENCIES_FILE_CONTENT})

    # Parse package name
    string(REGEX MATCH "^[a-zA-Z0-9.]*/" PACKAGE_NAME "${LINE}")
    STRING(REGEX REPLACE "/" "" PACKAGE_NAME "${PACKAGE_NAME}")

    if("${LINE}" MATCHES "\[[0-9.]*,[0-9.]*\]")

        # Parse package version min
        string(REGEX MATCH "\[[0-9.]*," PACKAGE_VERSION_MIN "${LINE}")
        STRING(REGEX REPLACE "\\[" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")
        STRING(REGEX REPLACE "," "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")

        # Parse package version max
        string(REGEX MATCH ",[0-9.]*\]" PACKAGE_VERSION_MAX "${LINE}")
        STRING(REGEX REPLACE "," "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")
        STRING(REGEX REPLACE "\]" "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")

        if(${CMAKE_VERSION} VERSION_LESS "3.19.0")
            message(WARNING "Wrong CMake version to use version range, will disable version check for cmake")

            # Disable version check for cmake
            set(PACKAGE_VERSION "")
        endif()
    else()

        # Parse package version
        string(REGEX MATCH "/[0-9.]*(@|$)" PACKAGE_VERSION "${LINE}")
        STRING(REGEX REPLACE "/" "" PACKAGE_VERSION "${PACKAGE_VERSION}")
        STRING(REGEX REPLACE "@" "" PACKAGE_VERSION "${PACKAGE_VERSION}")
    endif()

    # Parse package repository (conan)
    string(REGEX MATCH "@.*$" PACKAGE_REPOSITORY "${LINE}")
    STRING(REGEX REPLACE "@" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")
    STRING(REGEX REPLACE ";" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")

    # Check for system
    if(DEFINED PACKAGE_VERSION)
        find_package(${PACKAGE_NAME} ${PACKAGE_VERSION} QUIET)
    else()
        find_package(${PACKAGE_NAME} ${PACKAGE_VERSION_MIN}...${PACKAGE_VERSION_MAX} QUIET)
    endif()

    # Check if package found on system
    if(${${PACKAGE_NAME}_FOUND})
        message(STATUS "${PACKAGE_NAME} found in system")

        # The system handle the package
        include_directories(${PACKAGE_NAME}_INCLUDE_DIRS)
        link_libraries(${PACKAGE_NAME}_LIBRARIES)
    else()
        message(STATUS "${PACKAGE_NAME} not found in system")

        # Conan will handle
        STRING(REGEX REPLACE "\\[.*\\]" "[>=${PACKAGE_VERSION_MIN} <=${PACKAGE_VERSION_MAX}]" LINE "${LINE}")
        list(APPEND CONAN_DEPENDENCIES "${LINE}")
    endif()

endforeach()

# Conan
if(DEFINED CONAN_DEPENDENCIES)
    list(TRANSFORM CONAN_DEPENDENCIES TOLOWER)

    # Transform the list
    STRING(REGEX REPLACE ";" "\n" CONAN_DEPENDENCIES "${CONAN_DEPENDENCIES}")

    message(STATUS "${CONAN_DEPENDENCIES}")

    # Download Conan automatically, you can also just copy the conan.cmake file
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
        message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
        file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/master/conan.cmake" "${CMAKE_BINARY_DIR}/conan.cmake")
    endif()

    # Include conan cmake script
    include(${CMAKE_BINARY_DIR}/conan.cmake)

    # Add 'bincrafters' repository
    conan_add_remote(NAME bincrafters
            INDEX 1
            URL https://api.bintray.com/conan/bincrafters/public-conan
            VERIFY_SSL True)

    # Conan setup
    conan_cmake_run(REQUIRES ${CONAN_DEPENDENCIES}
                    BASIC_SETUP
                    GENERATORS cmake
                    IMPORTS "bin, *.dll -> ./bin"
                    IMPORTS "lib, *.dylib* -> ./bin"
                    IMPORTS "lib, *.so* -> ./bin"
                    BUILD missing)

    # Check if Conan exist
    if(NOT EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
        message(WARNING "You need to install Conan first https://conan.io/.")
    else()
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
        conan_basic_setup()
    endif()

    # Link dependencies to all targets
    link_libraries(${CONAN_LIBS})
endif()