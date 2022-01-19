#define WIN32_LEAN_AND_MEAN
//#include <Windows.h>
#include <iostream>
#include <RED4ext/RED4ext.hpp>

void MyGlobalFunc(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t a4)
{
    std::cout << "Hello from the global function!";

    if (aOut)
    {
        RED4ext::CString result("Returned from MyGlobalFunc");
        *aOut = result;
    }
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Load(RED4ext::PluginHandle aHandle, const RED4ext::IRED4ext* aInterface)
{
    auto rtti = RED4ext::CRTTISystem::Get();

    {
        auto func = RED4ext::CGlobalFunction::Create("MyGlobalFunc", "MyGlobalFunc", &MyGlobalFunc);
        func->SetReturnType("String");
        rtti->RegisterFunction(func);
    }

    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo* aInfo)
{
    aInfo->name = L"RED4ext.FunctionRegistration";
    aInfo->author = L"WopsS";
    aInfo->version = RED4EXT_SEMVER(1, 0, 0);
    aInfo->runtime = RED4EXT_RUNTIME_LATEST;
    aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_LATEST;
}
