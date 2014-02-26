#include <cstdlib>
#include <iostream>

#include "JVMLauncher.h"

int main(int argc, char** argv) {
    JVMLauncher* jvmlauncher = new JVMLauncher("C:\\");
    try {
        jvmlauncher->LaunchJVM();
    } catch (JVMLauncherException& ex) {
        std::cout << "Launching the JVM failed" << std::endl;
        std::cout << ex.what() << std::endl;
        std::cout << "Press any key to exit" << std::endl;
        std::cin.ignore(1);
    }
    return EXIT_SUCCESS;
}