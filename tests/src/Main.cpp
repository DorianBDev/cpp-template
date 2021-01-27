#define DOCTEST_CONFIG_IMPLEMENT
#include "doctest.h"

#include <exception>

int main(int argc, char* argv[])
{
    int res = 0;

    try
    {
        doctest::Context context;

        // Setup context
        context.applyCommandLine(argc, argv);

        // Run
        res = context.run();

        if (context.shouldExit())
            return res;
    }
    catch (std::exception& /* exception */)
    {
        return res;
    }

    return res;
}