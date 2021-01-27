############################################################################
########################### Project config #################################
############################################################################

#
# Project name
#
project("Project")

#
# Cpp version
#
set(CMAKE_CXX_STANDARD 17)

#
# Set the project type ('shared' for a shared library, 'static' for a static library or 'exe' for an executable)
#
set(PROJECT_TYPE "exe")


############################################################################
####################### Project linters config #############################
############################################################################

#
# Uncomment (or use command line) to enable/disable clang-format project wide tools (clang-format check and fix on whole projet) (not recommended)
#
#set(PROJECT_FORMAT_TOOLS "")

#
# Uncomment (or use command line) to enable/disable clang-tidy check/fix on modified code (not recommended)
#
#set(MODIFIED_CODE_TOOLS "")

#
# Uncomment (or use command line) to enable clang-tidy project wide automatic fixes (not recommended)
#
#set(CODE_FIX_TOOLS "")

#
# Uncomment (or use command line) to disable all linters targets.
#
#set(DISABLE_LINTERS "")


############################################################################
############################ Basic setup ###################################
############################################################################

cmake_minimum_required(VERSION 3.12.0)


message(STATUS "Using compiler: ${CMAKE_CXX_COMPILER}")

set(CMAKE_VERBOSE_MAKEFILE true)

#
# Set flags
#
if (NOT MSVC)
    add_definitions(-Wall -g)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc")
endif()

#
# Property for folders
#
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

#
# Configuration
#
if (CMAKE_SIZEOF_VOID_P MATCHES 8) # if x64
    message(STATUS "x64 configuration")
    set(CONFIGURATION "x64")
else() # if x86
    message(STATUS "x86 configuration")
    set(CONFIGURATION "x86")
endif()


############################################################################
############################ Dependencies ##################################
############################################################################

#
# Download Conan automatically, you can also just copy the conan.cmake file
#
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/master/conan.cmake" "${CMAKE_BINARY_DIR}/conan.cmake")
endif()

#
# Conan
#
include(${CMAKE_BINARY_DIR}/conan.cmake)
conan_cmake_run(CONANFILE DEPENDENCIES
        BASIC_SETUP
        BUILD missing)

#
# Check if Conan exist
#
if(NOT EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    message(WARNING "You need to install Conan first https://conan.io/.")
else()
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    conan_basic_setup()
endif()

#
# Link dependencies to all targets
#
link_libraries(${CONAN_LIBS})


############################################################################
################################ Version ###################################
############################################################################

#
# Version
#
include(${CMAKE_CURRENT_SOURCE_DIR}/etc/cmake/ConfigureFiles.cmake)

#
# Version command
#
add_custom_command(
        OUTPUT "${PROJECT_NAME} version" # Not an error, we need a dummy output to force command execution for every build
        COMMAND ${CMAKE_COMMAND} -DPROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR}"
                                 -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
                                 -DCONFIGURATION="${CONFIGURATION}"
                                 -P "${CMAKE_CURRENT_SOURCE_DIR}/etc/cmake/ConfigureFiles.cmake"
        DEPENDS "${PROJECT_SOURCE_DIR}/VERSION"
)


############################################################################
################################ Main ######################################
############################################################################

#
# The source files
#
file(GLOB_RECURSE SRC_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" LIST_DIRECTORIES false 
    "src/*.c"
	"src/*.cc"
	"src/*.cxx"
    "src/*.cpp"
    "src/*.h"
	"src/*.hxx"
    "src/*.hpp"
	"src/*.inl"
	"src/*.inc"
)

#
# Include directories
#
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

#
# Defines groups (to respect folders hierarchy)
#
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src" PREFIX "src" FILES ${SRC_FILES})

#
# Create target
#
if(PROJECT_TYPE STREQUAL "exe")
	
	# Remove main file
	set(CORE_SRC_FILES ${SRC_FILES})
	list(REMOVE_ITEM CORE_SRC_FILES "src/Main.cpp")
	
	# Create core
	add_library(${PROJECT_NAME}Core STATIC ${CORE_SRC_FILES} "${PROJECT_NAME} version")

	# Add executable
	add_executable(${PROJECT_NAME} "src/Main.cpp")
	target_link_libraries(${PROJECT_NAME} ${PROJECT_NAME}Core)
	
elseif(PROJECT_TYPE STREQUAL "static")

	# Added static library
	add_library(${PROJECT_NAME} STATIC ${SRC_FILES} "${PROJECT_NAME} version")
	
else()

	# Add shared library
	add_library(${PROJECT_NAME} SHARED ${SRC_FILES} "${PROJECT_NAME} version")
	
endif()


############################################################################
############################### Other ######################################
############################################################################

#
# Activate bundle for MacOS.
#
set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE TRUE)

#
# Installation specifications
#
install (TARGETS ${PROJECT_NAME} DESTINATION out/bin)

#
# Output specifications
#
set_target_properties(${PROJECT_NAME}
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "lib"
    LIBRARY_OUTPUT_DIRECTORY "lib"
    RUNTIME_OUTPUT_DIRECTORY "bin"
)

#
# Copy res folder contents
#
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/res $<TARGET_FILE_DIR:${PROJECT_NAME}>/res
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/res)
	
#
# No console on Windows when release.
#
if(MSVC) # If using the VS compiler...
    set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
endif()


############################################################################
############################### Tests ######################################
############################################################################

#
# Download doctest header automatically
#
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/lib/doctest.h")
	file(DOWNLOAD "https://raw.githubusercontent.com/onqtam/doctest/master/doctest/doctest.h" "${CMAKE_CURRENT_SOURCE_DIR}/tests/lib/doctest.h")
endif()

#
# Download first doctest cmake script automatically
#
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/cmake/doctest.cmake")
	file(DOWNLOAD "https://raw.githubusercontent.com/onqtam/doctest/master/scripts/cmake/doctest.cmake" "${CMAKE_CURRENT_SOURCE_DIR}/tests/cmake/doctest.cmake")
endif()

#
# Download second doctest cmake script automatically
#
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/cmake/doctestAddTests.cmake")
	file(DOWNLOAD "https://raw.githubusercontent.com/onqtam/doctest/master/scripts/cmake/doctestAddTests.cmake" "${CMAKE_CURRENT_SOURCE_DIR}/tests/cmake/doctestAddTests.cmake")
endif()

#
# Include tests
#
if(NOT DEFINED DISABLE_TESTS)
	add_subdirectory(tests)
endif()


############################################################################
################################ Doc #######################################
############################################################################

#
# Setup doxygen
#
find_package(Doxygen QUIET)
if(DOXYGEN_FOUND)
    message(STATUS "Doxygen found")

    add_custom_target(Documentation ALL
            COMMAND ${DOXYGEN_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/doc/config/DoxyFile"
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMENT "Generating documentation with Doxygen."
            SOURCES "${PROJECT_NAME} version")

else()
    message(STATUS "Doxygen not found")
endif()


############################################################################
############################## Linters #####################################
############################################################################

#
# Check if python is available
#
find_package (Python COMPONENTS Interpreter)

#
# Check if clang-tidy and clang-format are available
#
find_program(CLANG_FORMAT NAMES "clang-format")
find_program(CLANG_TIDY NAMES "clang-tidy")

#
# List of supported generators for code check (clang-tidy) (because it need support for CMAKE_EXPORT_COMPILE_COMMANDS)
#
set(SUPPORTED_CODE_CHECK_GENERATORS 
	"Borland Makefiles"
	"MSYS Makefiles"
	"MinGW Makefiles"
	"NMake Makefiles"
	"NMake Makefiles JOM"
	"Unix Makefiles"
	"Watcom WMake"
	"Ninja"
)

#
# If Python was found, setup linters
#
if(Python_FOUND AND NOT DEFINED DISABLE_LINTERS)

    # Status message about python
    message(STATUS "Python was found")

    # Transform src files
    list(TRANSFORM SRC_FILES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")

    # Filtered src folder path
    string(REGEX REPLACE "/" "." SOURCE_DIR_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src/.*")
	
	# Export commands
	set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # Clang-tidy
    if(CLANG_TIDY AND ${CMAKE_GENERATOR} IN_LIST SUPPORTED_CODE_CHECK_GENERATORS)

        message(STATUS "Clang-tidy was found")

        # Download run-clang-tidy scripts automatically
        if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/run-clang-tidy.py")
            file(DOWNLOAD "https://raw.githubusercontent.com/llvm/llvm-project/release/9.x/clang-tools-extra/clang-tidy/tool/run-clang-tidy.py" "${CMAKE_CURRENT_BINARY_DIR}/run-clang-tidy.py")
        endif()

        # Add target for clang-tidy
        add_custom_target(CheckCode
                COMMAND python run-clang-tidy.py -config="" -p=${CMAKE_CURRENT_BINARY_DIR} -header-filter="${SOURCE_DIR_PATH}"
                DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run-clang-tidy.py
                        ${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy)
		
		# Set target folder (Linters)
		set_target_properties(CheckCode PROPERTIES FOLDER Linters)

		if(DEFINED CODE_FIX_TOOLS)
		
			# Add target for clang-tidy fix
			add_custom_target(FixCode
					COMMAND python run-clang-tidy.py -config="" -p=${CMAKE_CURRENT_BINARY_DIR} -header-filter="${SOURCE_DIR_PATH}" -fix
					DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run-clang-tidy.py
							${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy)
							
			# Set target folder (Linters)
			set_target_properties(FixCode PROPERTIES FOLDER Linters)
							
		endif()

		if(DEFINED MODIFIED_CODE_TOOLS)

			# Download clang-tidy-diff scripts automatically
			if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py")
				file(DOWNLOAD "https://raw.githubusercontent.com/llvm/llvm-project/release/9.x/clang-tools-extra/clang-tidy/tool/clang-tidy-diff.py" "${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py")
			endif()

			# Add target for clang-tidy-diff
			add_custom_target(CheckModifiedCode
					COMMAND git diff -U0 HEAD | python ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py -p1 -path="${CMAKE_CURRENT_BINARY_DIR}"
					WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
					DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py
							${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy)
							
			# Set target folder (Linters)
			set_target_properties(CheckModifiedCode PROPERTIES FOLDER Linters)

			if(DEFINED CODE_FIX_TOOLS)

				# Add target for clang-tidy-diff fix
				add_custom_target(FixModifiedCode
						COMMAND git diff -U0 HEAD | python ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py -p1 -fix -path="${CMAKE_CURRENT_BINARY_DIR}"
						WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
						DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy-diff.py
								${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy)
								
				# Set target folder (Linters)
				set_target_properties(FixModifiedCode PROPERTIES FOLDER Linters)
							
			endif()

		endif()
    endif()

    # Clang-format
    if(CLANG_FORMAT)

        message(STATUS "Clang-format was found")

		if(DEFINED PROJECT_FORMAT_TOOLS)

			# Add target for clang-format
			add_custom_target(CheckProjectFormat
					COMMAND clang-format -style=file ${SRC_FILES} --dry-run
					DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)
					
			# Set target folder (Linters)
			set_target_properties(CheckProjectFormat PROPERTIES FOLDER Linters)

			# Add target for clang-format fix
			add_custom_target(FixProjectFormat
					COMMAND clang-format -style=file ${SRC_FILES} -i
					DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)
					
			# Set target folder (Linters)
			set_target_properties(FixProjectFormat PROPERTIES FOLDER Linters)
		
		endif()

        # Download clang-format-diff scripts automatically
        if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py")
            file(DOWNLOAD "https://raw.githubusercontent.com/llvm/llvm-project/release/9.x/clang/tools/clang-format/clang-format-diff.py" "${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py")
        endif()

        # Add target for clang-format-diff
        add_custom_target(CheckFormat
                COMMAND git diff -U0 HEAD^ | python ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py -p1
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py
                        ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)
						
		# Set target folder (Linters)
		set_target_properties(CheckFormat PROPERTIES FOLDER Linters)

        # Add target for clang-format-diff fix
        add_custom_target(FixFormat
                COMMAND git diff -U0 HEAD^ | python ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py -p1 -i
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py
                        ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)
						
		# Set target folder (Linters)
		set_target_properties(FixFormat PROPERTIES FOLDER Linters)
		
		if(DEFINED CHECK_FORMAT_PREV_DIFF)
		
			# Add target for clang-format-diff (for previous commit)
			add_custom_target(CheckDiffFormat
					COMMAND git diff -U0 HEAD^ HEAD | python ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py -p1 > ${CMAKE_CURRENT_SOURCE_DIR}/build/patch.txt
					WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
					DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-format-diff.py
							${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)
							
		endif()
						
    endif()

endif()


############################################################################
############################# VALGRIND #####################################
############################################################################

find_program(VALGRIND_EXE NAMES "valgrind")
if(VALGRIND_EXE)

    # Add target for valgrind
	add_custom_target(Valgrind
			COMMAND ${VALGRIND_EXE} --tool=memcheck --leak-check=yes --show-reachable=yes --track-fds=yes --error-exitcode=1 $<TARGET_FILE:${PROJECT_NAME}Tests>)

	# Link tests to Valgrind target
	add_dependencies(Valgrind ${PROJECT_NAME}Tests)
		
endif()