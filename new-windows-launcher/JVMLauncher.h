#ifndef JVMLAUNCHER_H
#define	JVMLAUNCHER_H

#include <stdexcept>
#include <windows.h>
#include <tchar.h>
#include <jni.h>
#include <string>
#include <stdlib.h>
#include <vector>
#include <iostream>
#include <ostream>
#include "JVMLauncherException.cpp"

class JVMLauncher {
public:
    JVMLauncher(std::string);
    void LaunchJVM();
private:
    typedef jint(JNICALL *CreateJavaVM)(JavaVM **pvm, void **penv, void *args);
    HINSTANCE jvmDllInstance;
    std::string javaHome;
    std::string appHome;
    std::string jvmDll;
    std::vector<std::string> jars;
    CreateJavaVM jvmInstance;
    jclass mainClass;
    jmethodID mainMethod;
    JNIEnv *jvmEnv;
    JavaVM *jvm;
    void checkForException();
protected:
};

#endif	/* JVMLAUNCHER_H */

