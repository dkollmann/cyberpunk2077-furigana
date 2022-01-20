#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <RED4ext/RED4ext.hpp>
#include <mecab.h>
#include <string>
#include <vector>
#include <iostream>

template<typename T> bool ToWChar(const char *utf8, T &wchar)
{
    const int ln = (int) std::strlen(utf8);
    const int sz = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8, ln, nullptr, 0);

    if(sz == 0)
        return false;

    wchar.resize(sz);

    const int sz2 = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8, ln, (wchar_t*) wchar.data(), sz);

    return sz2 != 0;
}

void MecabParse(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd


    std::vector<wchar_t> wstring;

    const MeCab::Node* node = MeCab::createTagger("")->parseToNode((const char*) u8"隣の客はよく柿食う客だ。");
    for(; node; node = node->next)
    {
        switch(node->stat)
        {
        case MECAB_BOS_NODE:
        case MECAB_EOS_NODE:
            continue;

        default:
            std::cout
                << node->feature
                //        << ' ' << (int)(node->surface - input)
                //        << ' ' << (int)(node->surface - input + node->length)
                //        << ' ' << node->rcAttr
                //        << ' ' << node->lcAttr
                //        << ' ' << node->posid
                //        << ' ' << (int)node->char_type
                //        << ' ' << (int)node->stat
                //        << ' ' << (int)node->isbest
                //        << ' ' << node->alpha
                //        << ' ' << node->beta
                //        << ' ' << node->prob
                //        << ' ' << node->cost
                << std::endl;

            ToWChar(node->feature, wstring);

            MessageBox(NULL, wstring.data(), L"Furigana", MB_OK);
        }
    }

    if(aOut != nullptr)
    {
        *aOut = 0;
    }
}

void StrOrd(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString text;
    int index = 0;

    RED4ext::GetParameter(aFrame, &text);
    RED4ext::GetParameter(aFrame, &index);

    aFrame->code++; // skip ParamEnd

    if(aOut != nullptr)
    {
        int len = (int) text.Length();

        if(index >= 0 && index < len)
        {
            *aOut = (int) text.c_str()[index];
        }
        else
        {
            *aOut = 0;
        }
    }
}

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes()
{
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes()
{
    //MessageBoxA(NULL, "Registered Furigana DLL", "Furigana DLL", MB_OK);

    auto rtti = RED4ext::CRTTISystem::Get();
    const RED4ext::CBaseFunction::Flags flags = { .isNative = true, .isStatic = true };

    {
        auto func = RED4ext::CGlobalFunction::Create("StrOrd", "StrOrd", &StrOrd);
        func->flags = flags;
        func->AddParam("String", "text");
        func->AddParam("Int32", "index");
        func->SetReturnType("Int32");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("MecabParse", "MecabParse", &MecabParse);
        func->flags = flags;
        func->AddParam("String", "text");
        func->SetReturnType("Int32");
        rtti->RegisterFunction(func);
    }
}

BOOL APIENTRY DllMain(HMODULE aModule, DWORD aReason, LPVOID aReserved)
{
    switch (aReason)
    {
    case DLL_PROCESS_ATTACH:
        RED4ext::RTTIRegistrator::Add(RegisterTypes, PostRegisterTypes);
        break;

    case DLL_PROCESS_DETACH:
        break;
    }

    return TRUE;
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Load(RED4ext::PluginHandle aHandle, const RED4ext::IRED4ext* aInterface)
{
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo* aInfo)
{
    aInfo->name = L"Cyberpunk 2077 Furigana";
    aInfo->author = L"Daniel Kollmann";
    aInfo->version = RED4EXT_SEMVER(1, 0, 0);
    aInfo->runtime = RED4EXT_RUNTIME_LATEST;
    aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_LATEST;
}

// ++++++++++++++++++++++++++++++++++++++
//   Mecap error handling
// ++++++++++++++++++++++++++++++++++++++

namespace {
    const size_t kErrorBufferSize = 256;
    char kErrorBuffer[kErrorBufferSize];
}

const char* getGlobalError() {
    return kErrorBuffer;
}

void setGlobalError(const char* str) {
    strncpy(kErrorBuffer, str, kErrorBufferSize - 1);
    kErrorBuffer[kErrorBufferSize - 1] = '\0';
}
