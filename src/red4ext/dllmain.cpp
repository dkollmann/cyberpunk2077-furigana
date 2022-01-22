#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <RED4ext/RED4ext.hpp>
#include <vector>
#include <assert.h>

constexpr bool iskanji(int n)
{
    // must be the same as from the python script that generates the furigana
    return (n >= 19968 && n <= 40959) || n == 12293 || n == 12534;
}

template<typename T> bool ToWChar(const char* utf8, T& wchar)
{
    const int ln = (int) std::strlen(utf8);
    const int sz = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8, ln, nullptr, 0);

    if(sz == 0)
        return false;

    wchar.resize(sz);

    const int sz2 = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8, ln, (wchar_t*) wchar.data(), sz);

    return sz2 != 0;
}

#define RETURN_EMPTY_LIST() {*aOut = 0; return;}

void StrSplitFurigana(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    // check if there are actually furigana in there
    auto textstr = text.c_str();
    const int len = (int) text.Length();
    bool hasfurigana = false;
    for(int i = 0; i < len; ++i)
    {
        if( textstr[i] == '{' )
        {
            hasfurigana = true;
            break;
        }
    }

    // handle the simple case that there is no furigana
    if(!hasfurigana)
        RETURN_EMPTY_LIST();

    // we have furigana so we have to start extracting it. This is easier with wchar_t.
    std::vector<wchar_t> subtitle;
    if( !ToWChar(textstr, subtitle) )
        RETURN_EMPTY_LIST();

    const int subtitlelen = (int) subtitle.size();

    enum class type : int { text = 0, kanji = 1, furigana = 2 };
    struct frag { int from; int to; type tpe; };

    std::vector<frag> fragments;
    fragments.reserve(8);

    int start = 0;
    bool insideblock = false;
    for(int i = 0; i < subtitlelen && start <= i; ++i)
    {
        const wchar_t ch = subtitle[i];

        if(insideblock)
        {
            if(ch == L'}')
            {
                // add the furigana block
                fragments.push_back({start, i - 1, type::furigana});

                // continue outside of the block
                start = i + 1;
                insideblock = false;
            }
        }
        else
        {
            if(ch == L'{')
            {
                // find kanjis
                int j;
                for(j = i - 1; j >= start; --j)
                {
                    const wchar_t ch2 = subtitle[j];

                    if( !iskanji(ch2) )
                        break;
                }
                j++;

                // check if we are good
                assert(j >= start && j < i);
                if(j >= i)
                    RETURN_EMPTY_LIST();

                // add the text block before the kanji
                if(j > start)
                    fragments.push_back({start, j - 1, type::text});

                // add the kanji block
                fragments.push_back({j, i - 1, type::kanji});

                // continue the block
                start = i + 1;
                insideblock = true;
            }
        }
    }

    assert(!insideblock);

    if(start < subtitlelen)
    {
        // add the text at the end
        fragments.push_back({start, subtitlelen - 1, type::text});
    }

    *aOut = (int) fragments.size();
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
        auto func = RED4ext::CGlobalFunction::Create("StrSplitFurigana", "StrSplitFurigana", &StrSplitFurigana);
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
