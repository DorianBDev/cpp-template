# Print system dependencies check status
if(DEFINED DISABLE_SYSTEM_DEPENDENCIES)
    message(STATUS "No check for dependencies on the system")
endif()

# Print conan status
if(DEFINED DISABLE_CONAN_DEPENDENCIES)
    message(STATUS "Conan is disabled")
endif()

# Read dependencies file
file(READ "${PROJECT_SOURCE_DIR}/DEPENDENCIES" DEPENDENCIES_FILE_CONTENT)

# Create the list
string(REGEX REPLACE "\n" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Clear empty list entries
string(REGEX REPLACE ";;" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Remove lines that start with a '#'
foreach(LINE ${DEPENDENCIES_FILE_CONTENT})
    if("${LINE}" MATCHES "^(#.*|\\n)")
        list(REMOVE_ITEM DEPENDENCIES_FILE_CONTENT "${LINE}")
        continue()
    endif()
endforeach()

# Clear empty list entries
string(REGEX REPLACE ";;" ";" DEPENDENCIES_FILE_CONTENT "${DEPENDENCIES_FILE_CONTENT}")

# Parse dependencies
foreach(LINE ${DEPENDENCIES_FILE_CONTENT})

    # Remove any space in the line
    string(REGEX REPLACE " " "" LINE "${LINE}")

    # Set default values for start options (system only or conan only)
    set(PACKAGE_SYSTEM_ONLY FALSE)
    set(PACKAGE_CONAN_ONLY FALSE)

    # System only
    if(LINE MATCHES "^!.*")
        set(PACKAGE_SYSTEM_ONLY TRUE)
        message(STATUS "${LINE}: System only")
        string(REGEX REPLACE "!" "" LINE "${LINE}")
    endif()

    # Conan only
    if(LINE MATCHES "^\\?.*")
        set(PACKAGE_CONAN_ONLY TRUE)
        message(STATUS "${LINE}: Conan only")
        string(REGEX REPLACE "\\?" "" LINE "${LINE}")
    endif()

    # Parse package name
    string(REGEX MATCH "^[a-zA-Z0-9.]*/" PACKAGE_NAME "${LINE}")
    string(REGEX REPLACE "/" "" PACKAGE_NAME "${PACKAGE_NAME}")

    # Reset variables
    set(VERSION_SIMPLE FALSE)
    set(VERSION_RANGE FALSE)
    set(VERSION_MIN FALSE)

    if("${LINE}" MATCHES "\[[0-9.]*,[0-9.]*\]")

        # Parse package version min
        string(REGEX MATCH "\[[0-9.]*," PACKAGE_VERSION_MIN "${LINE}")
        string(REGEX REPLACE "\\[" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")
        string(REGEX REPLACE "," "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")

        # Parse package version max
        string(REGEX MATCH ",[0-9.]*\]" PACKAGE_VERSION_MAX "${LINE}")
        string(REGEX REPLACE "," "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")
        string(REGEX REPLACE "\]" "" PACKAGE_VERSION_MAX "${PACKAGE_VERSION_MAX}")

        set(VERSION_RANGE TRUE)

    elseif("${LINE}" MATCHES "\[[0-9.]*\]")

        # Parse package version min
        string(REGEX MATCH "\[[0-9.]*\]" PACKAGE_VERSION_MIN "${LINE}")
        string(REGEX REPLACE "\\[" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")
        string(REGEX REPLACE "\]" "" PACKAGE_VERSION_MIN "${PACKAGE_VERSION_MIN}")

        set(VERSION_MIN TRUE)

    else()

        # Parse package version
        string(REGEX MATCH "/[0-9.]*(@|$)" PACKAGE_VERSION "${LINE}")
        string(REGEX REPLACE "/" "" PACKAGE_VERSION "${PACKAGE_VERSION}")
        string(REGEX REPLACE "@" "" PACKAGE_VERSION "${PACKAGE_VERSION}")

        set(VERSION_SIMPLE TRUE)

    endif()

    # Parse package repository (conan)
    string(REGEX MATCH "@.*$" PACKAGE_REPOSITORY "${LINE}")
    string(REGEX REPLACE "@" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")
    string(REGEX REPLACE ";" "" PACKAGE_REPOSITORY "${PACKAGE_REPOSITORY}")

    # By default, conan will not handle
    set(CONAN_WILL_HANDLE FALSE)

    # System dependencies check
    if(NOT DEFINED DISABLE_SYSTEM_DEPENDENCIES AND NOT PACKAGE_CONAN_ONLY)

        # Check for dependencies on the system
        find_package(${PACKAGE_NAME} QUIET)

        # Check if package found on the system
        if(${${PACKAGE_NAME}_FOUND})
            message(STATUS "${PACKAGE_NAME} found on the system")

            if(NOT DEFINED ${${PACKAGE_NAME}_VERSION})
                message(STATUS "${PACKAGE_NAME} on the system don't have proper version number.")
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
                message(STATUS "${PACKAGE_NAME} on the system match version needs.")

                # The system handle the package
                include_directories(${PACKAGE_NAME}_INCLUDE_DIRS)
                link_libraries(${PACKAGE_NAME}_LIBRARIES)

            else()

                # Warning message (or not, if conan is available)
                if(NOT DEFINED DISABLE_CONAN_DEPENDENCIES)
                    message(STATUS "${PACKAGE_NAME} on the system don't match version needs.")
                else()
                    message(WARNING "${PACKAGE_NAME} on the system don't match version needs and Conan is disabled.")
                endif()

                # Conan will handle this
                set(CONAN_WILL_HANDLE TRUE)

            endif()

        else()

            # Warning message (or not, if conan is available)
            if(NOT DEFINED DISABLE_CONAN_DEPENDENCIES)
                message(STATUS "${PACKAGE_NAME} not found on the system.")
            else()
                message(WARNING "${PACKAGE_NAME} not found on the system and Conan is disabled.")
            endif()

            # Conan will handle this
            set(CONAN_WILL_HANDLE TRUE)

        endif()

    else()
        set(CONAN_WILL_HANDLE TRUE)
    endif()

    # Conan will handle
    if(CONAN_WILL_HANDLE AND NOT PACKAGE_SYSTEM_ONLY)

        if(VERSION_SIMPLE) # Version only

            string(REGEX REPLACE "\\[.*\\]" "${PACKAGE_VERSION}" LINE "${LINE}")

        elseif(VERSION_RANGE) # Min and max version

            string(REGEX REPLACE "\\[.*\\]" "[>=${PACKAGE_VERSION_MIN} <=${PACKAGE_VERSION_MAX}]" LINE "${LINE}")

        else() # Min version

            string(REGEX REPLACE "\\[.*\\]" "[>=${PACKAGE_VERSION_MIN}]" LINE "${LINE}")

        endif()

        # Happen list
        list(APPEND CONAN_DEPENDENCIES "${LINE}")

        # Print information
        if (NOT DEFINED DISABLE_CONAN_DEPENDENCIES)
            message(STATUS "Conan will handle: ${LINE}")
        endif()

    endif()

endforeach()

# Conan
if(DEFINED CONAN_DEPENDENCIES)

    # If conan is enabled
    if(NOT DEFINED DISABLE_CONAN_DEPENDENCIES)

        # Convert packages to lowercase
        list(TRANSFORM CONAN_DEPENDENCIES TOLOWER)

        # Transform the list
        string(REGEX REPLACE ";" "\n" CONAN_DEPENDENCIES "${CONAN_DEPENDENCIES}")

        message(STATUS "Conan dependencies:\n${CONAN_DEPENDENCIES}")

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

        # Replace Conan options separators with new line
        string(REGEX REPLACE " " "\n" CONAN_OPTIONS "${CONAN_OPTIONS}")
        string(REGEX REPLACE ";" "\n" CONAN_OPTIONS "${CONAN_OPTIONS}")
        string(REGEX REPLACE "\n\n" "\n" CONAN_OPTIONS "${CONAN_OPTIONS}")

        message(STATUS "Conan options:\n${CONAN_OPTIONS}")

        # Conan setup
        conan_cmake_run(REQUIRES ${CONAN_DEPENDENCIES}
                        OPTIONS ${CONAN_OPTIONS}
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

    else()
        message(FATAL_ERROR "Conan is disabled but some packages aren't available on the system.")
    endif()
endif()