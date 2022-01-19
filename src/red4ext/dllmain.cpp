#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
//#include <Windows.h>
#include <iostream>
#include <RED4ext/RED4ext.hpp>

void StrOrd(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString *text = nullptr;
    int index = 0;

    RED4ext::GetParameter(aFrame, &text);
    RED4ext::GetParameter(aFrame, &index);

    aFrame->code++; // skip ParamEnd

    if(aOut != nullptr)
    {
        int len = (int) text->length;

        if(index >= 0 && index < len)
        {
            *aOut = (int) text->text.ptr[index];
        }
        else
        {
            *aOut = 0;
        }
    }
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Load(RED4ext::PluginHandle aHandle, const RED4ext::IRED4ext* aInterface)
{
    auto rtti = RED4ext::CRTTISystem::Get();

    {
        auto func = RED4ext::CGlobalFunction::Create("StrOrd", "StrOrd", &StrOrd);
        func->AddParam("String", "text");
        func->AddParam("Int32", "index");
        func->SetReturnType("Int32");
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
