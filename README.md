# cpp-template v2

To adapt this template, you just need to edit the 'CMakeLists.txt' file with project information.

Also you can edit files in the root folder to suit your needs.

This template was made by [**Dorian Bachelot**](https://github.com/DorianBDev) <dev@dorianb.net>.

## Presentation

This template use CMake and Conan (optional but recommended). Conan is a package manager for C/C++ written in python. 
All is automated thanks to these tools.

## Add dependencies

To add a new dependency, just edit the 'DEPENDENCIES' file and add the dependency name. To search a package, please 
visit: https://conan.io/center/ or https://bintray.com/bincrafters/public-conan.

The 'DEPENDENCIES' file has many options that you can use like checking on the system if a requested dependency is on 
already installed or also discard the version check (for the system check only). To see every option, you can open the
'DEPENDENCIES' file and you will find documentation at the top of it.

Also, this file can be adapted by each user by creating a copy with the name 'DEPENDENCIES.local' which will be 
ignored by git. This allows a more "user" personalization of the dependency system.

You can also add a FindXXX.cmake file in the etc/cmake directory if the package finder script is not present in 
cmake by default.

If you don't want to use Conan, you can specify dependency path (by continuing to use the same 'DEPENDENCIES' file) 
with the CMake options (<package name> is case sensitive, it needs to have the same case as in the 'DEPENDENCIES' file):
```console
> cmake .. -D<package name>_DEPENDENCY_PATH=<path>
```

# Build

## Dependencies

- CMake 3.12.0 or newer,
- Conan (optional),
- Python (optional).

## Quick start

Firstly, clone this repository (help [here](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)).

In all cases you need to specify to CMake the build type ('Debug' or 'Release') with this option:
```console
> -DCMAKE_BUILD_TYPE=Debug
```

### For Linux (debian-like)

Install dependencies:
```console
> sudo apt-get install cmake g++ python
> sudo pip install conan
```
Build (in the 'build' folder, for example):
```console
> cmake .. -DCMAKE_BUILD_TYPE=Debug
> make
```
Binaries are in the 'build/bin' folder.

### For Windows

Install dependencies:
- CMake: https://cmake.org/download/,
- A compiler (for example MSVC): https://visualstudio.microsoft.com/,
- Conan: https://conan.io/,
- Python: https://www.python.org/ (optional).

Build (in the 'build' folder, for example):
```console
> cmake .. -DCMAKE_BUILD_TYPE=Debug
> cmake --build .
```
Binaries are in the 'build/bin' folder.

### For MacOS

Install dependencies (we will use [Homebrew](https://brew.sh) here) :
- XCode: https://apps.apple.com/app/xcode/id497799835

```console
> brew install python
> brew install conan
```

Build (in the 'build' folder, for example):
```console
> cmake .. -DCMAKE_BUILD_TYPE=Debug
> cmake --build .
```
Binaries are in the 'build/bin' folder in the bundle ".app" format.

# Contributing

Read the "CONTRIBUTING.md" file.

# License

MIT license. See LICENSE.TXT for details.

The current main maintainer of this template is **Dorian Bachelot** <dev@dorianb.net>.
