# Template

To adapt this template, you just need to edit the 'CMakeLists.txt' file with project information.

Also you can edit files in the root folder to adapt for your needs.

## Presentation

This template use CMake and conan. Conan is a package manager for C/C++ written in python. All is automated thanks to these tools.

## Add dependencies

Just edit the 'DEPENDENCIES' file and add dependencies names. To search a package, please visit: https://conan.io/center/.

# Build

## Dependencies

- CMake 3.12.0 or newer,
- Conan,
- Python (optional).

## Quick start

Firstly, clone this repository (help [here](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)).

### For Linux (debian-like)

Install dependencies:
```console
> sudo apt-get install cmake g++ python
> sudo pip install conan
```
Build (in the 'build' folder, for example):
```console
> cmake ..
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
> cmake ..
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
> cmake ..
> cmake --build .
```
Binaries are in the 'build/bin' folder in the bundle ".app" format.

# Contributing

Read the "CONTRIBUTING.md" file.

# License

MIT license. See LICENSE.TXT for details.

The current main maintainer of Degate is **Dorian Bachelot** <dev@dorianb.net>.
