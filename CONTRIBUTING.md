# Contributing

Any help is not just welcome, but also essential and precious to maintain and improve this project. Feel free to help on all aspects of the project, from bug reports to code contributions. This project (and this repository) is for the community and by the community.

## Pull request

A pull request template is provided.

## Style guide

You can find a .clang-format file (to use with clang-format) describing the project code style in the root folder of the repository. Also, you can find a .clang-tidy file (to use with clang-tidy)  to help you with good coding practices with the project.

The naming convention is:

| Element           | Case          |
| ----------------- | ------------- |
| Class/Struct/Enum | CamelCase     |
| Variable          | camelBack     |
| Function          | camelBack     |
| Parameter         | camelBack     |
| Enum constant     | UPPER_CASE    |
| Macro             | UPPER_CASE    |
| Namespace         | camelBack     |

The header guard style convention is:
````cpp
[EXTENSION]_[PROJECT NAME]_[FILE PATH FROM src]_[EXTENSION]
```` 

For example, for the file 'src/Example/Example.hpp' the header guard will be:
````cpp
HPP_PROJECT_EXAMPLE_EXAMPLE_HPP
````

Comments style is as follows:
```cpp
// Class/Struct
/**
 * @class MyClass
 * @brief Short class description.
 * 
 * Long description
 * 
 * @see OtherClass
 */
class MyClass
{
public:
    /**
     * @brief Function to add to number.
     * 
     * @param first  First number.
     * @param second Second number.
     * 
     * @return Returns result of first + second.
     * 
     * @throw MyException Exception description.
     */
    int add(int first, int second);
    
private:
    /**
     * My variable description.
     */
    int myVariable;
};

// Enum
/**
 * @enum MyEnum
 * @brief Brief description.
 * 
 * Long description.
 * 
 * @see OtherClass
 */
enum MyEnum
{
    ENUM_1, /*!< My ENUM_1 description. */
    ENUM_2  /*!< My ENUM_2 description. */
};
```

## Documentation

You can build the project **code** documentation to help you (in the "doc" folder), see the "doc/README.md" file for more.
