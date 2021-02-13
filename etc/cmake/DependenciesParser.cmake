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

    # Remove any space in the line
    STRING(REGEX REPLACE " " "" LINE "${LINE}")

    # Parse package name
    string(REGEX MATCH "^[a-zA-Z0-9.]*/" PACKAGE_NAME "${LINE}")
    STRING(REGEX REPLACE "/" "" PACKAGE_NAME "${PACKAGE_NAME}")

    # Reset variables
    set(VERSION_SIMPLE FALSE)
    set(VERSION_RANGE FALSE)
    set(VERSION_MIN FALSE)

    if("${LINE}" MATCHES "\[[0-9.]*,[0-9.]*\]")

        # Parse package version min
        string(REGEX MATCH "\[[0-9.]*," PACKAGE_VERSION_MIN "${LINE}")
        STRING(REGEX REPLACE "\\[" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")
        STRING(REGEX REPLACE "," "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")

        # Parse package version max
        string(REGEX MATCH ",[0-9.]*\]" PACKAGE_VERSION_MAX "${LINE}")
        STRING(REGEX REPLACE "," "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")
        STRING(REGEX REPLACE "\]" "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")

        set(VERSION_RANGE TRUE)

    elseif("${LINE}" MATCHES "\[[0-9.]*\]")

        # Parse package version min
        string(REGEX MATCH "\[[0-9.]*\]" PACKAGE_VERSION_MIN "${LINE}")
        STRING(REGEX REPLACE "\\[" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")
        STRING(REGEX REPLACE "\]" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")

        set(VERSION_MIN TRUE)

    else()

        # Parse package version
        string(REGEX MATCH "/[0-9.]*(@|$)" PACKAGE_VERSION "${LINE}")
        STRING(REGEX REPLACE "/" "" PACKAGE_VERSION "${PACKAGE_VERSION}")
        STRING(REGEX REPLACE "@" "" PACKAGE_VERSION "${PACKAGE_VERSION}")

        set(VERSION_SIMPLE TRUE)

    endif()

    # Parse package repository (conan)
    string(REGEX MATCH "@.*$" PACKAGE_REPOSITORY "${LINE}")
    STRING(REGEX REPLACE "@" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")
    STRING(REGEX REPLACE ";" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")

    # By default, conan will not handle
    set(CONAN_WILL_HANDLE FALSE)

    # Check for system
    find_package(${PACKAGE_NAME} QUIET)

    # Check if package found on system
    if(${${PACKAGE_NAME}_FOUND})
        message(STATUS "${PACKAGE_NAME} found in system")

        if(NOT DEFINED ${${PACKAGE_NAME}_VERSION})
            message(STATUS "${PACKAGE_NAME} on system don't have proper version number.")
            set(CONAN_WILL_HANDLE TRUE)
        endif()

        set(PACKAGE_VERSION_MATCH FALSE)

        if(VERSION_SIMPLE) # Version only

            # Check if the version is equal to the defined version
            if(${${PACKAGE_NAME}_VERSION} VERSION_EQUAL ${PACKAGE_VERSION})
                set(PACKAGE_VERSION_MATCH TRUE)
            endif()

        elseif(VERSION_RANGE) # Min and max version

            # Check if the version inside the min and max version interval
            if(${${PACKAGE_NAME}_VERSION} VERSION_LESS_EQUAL ${PACKAGE_VERSION_MAX} AND ${${PACKAGE_NAME}_VERSION} VERSION_GREATER_EQUAL ${PACKAGE_VERSION_MIN})
                set(PACKAGE_VERSION_MATCH TRUE)
            endif()

        else() # Min version

            # Check if the version is greater or equal than the defined min version
            if(${${PACKAGE_NAME}_VERSION} VERSION_GREATER_EQUAL ${PACKAGE_VERSION_MIN})
                set(PACKAGE_VERSION_MATCH TRUE)
            endif()

        endif()

        # Check if the version match
        if(PACKAGE_VERSION_MATCH)
            message(STATUS "${PACKAGE_NAME} on system match version needs.")

            # The system handle the package
            include_directories(${PACKAGE_NAME}_INCLUDE_DIRS)
            link_libraries(${PACKAGE_NAME}_LIBRARIES)

        else()
            message(STATUS "${PACKAGE_NAME} on system don't match version needs.")
            set(CONAN_WILL_HANDLE TRUE)
        endif()

    else()
        message(STATUS "${PACKAGE_NAME} not found in system")
        set(CONAN_WILL_HANDLE TRUE)
    endif()

    # Conan will handle
    if(CONAN_WILL_HANDLE)

        if(VERSION_SIMPLE) # Version only

            STRING(REGEX REPLACE "\\[.*\\]" "${PACKAGE_VERSION}" LINE "${LINE}")

        elseif(VERSION_RANGE) # Min and max version

            STRING(REGEX REPLACE "\\[.*\\]" "[>=${PACKAGE_VERSION_MIN} <=${PACKAGE_VERSION_MAX}]" LINE "${LINE}")

        else() # Min version

            STRING(REGEX REPLACE "\\[.*\\]" "[>=${PACKAGE_VERSION_MIN}]" LINE "${LINE}")

        endif()

        # Happen list
        list(APPEND CONAN_DEPENDENCIES "${LINE}")

        message(STATUS "Version : ${LINE}")

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