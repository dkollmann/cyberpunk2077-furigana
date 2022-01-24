#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
//#include <Windows.h>
#include <RED4ext/RED4ext.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/TextWidget.hpp>
#include "utf8proc/utf8proc.h"
#include <vector>
#include <assert.h>

template<typename T> class vectorstring : public std::vector<T>
{
public:

    void addstring(const T *str, int start, int end)
    {
        assert(start >= 0 && end >= start);

        size_t len = (size_t)(end - start + 1);
        size_t pos = this->size();

        this->resize(pos + len);

        std::memcpy(this->data() + pos, str + start, len * sizeof(T));
    }

    void addzero()
    {
        this->push_back((T)0);
    }
};

constexpr bool iskanji(int n)
{
    // must be the same as from the python script that generates the furigana
    return (n >= 19968 && n <= 40959) || n == 12293 || n == 12534;
}

enum class StrSplitFuriganaListType : short
{
    Text = 0,
    Kanji = 1,
    Furigana = 2
};

typedef RED4ext::DynArray<short> StrSplitFuriganaList;

void AddFragment(StrSplitFuriganaList &fragments, int start, int len, StrSplitFuriganaListType type)
{
    assert(start >= 0);
    assert(len > 0);

    fragments.PushBack((short)start);
    fragments.PushBack((short)len);
    fragments.PushBack((short)type);
}

void StrSplitFurigana(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, StrSplitFuriganaList* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    StrSplitFuriganaList &fragments = *aOut;

    // check if there are actually furigana in there
    auto textstr = text.c_str();
    const int textsize = (int) text.Length();
    bool hasfurigana = false;
    for(int i = 0; i < textsize; ++i)
    {
        // this is okay because it is an ascii character
        if( textstr[i] == '{' )
        {
            hasfurigana = true;
            break;
        }
    }

    // handle the simple case that there is no furigana
    if(!hasfurigana)
        return;

    fragments.Reserve(64);

    int start = 0;
    int kanjiblock = -1;
    int kanjisize = 0;
    int lastsize = 0;
    bool insideblock = false;

    auto subtitle = (const utf8proc_uint8_t*) textstr;
    for(int index = 0; index < textsize; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate(subtitle + index, -1, &ch);

        if(chsize <= 0)
            break;

        // process the character
        if(insideblock)
        {
            if(ch == (int)'}')
            {
                // add the furigana block
                AddFragment(fragments, start, index - start, StrSplitFuriganaListType::Furigana);

                // continue outside of the block
                start = index + chsize;
                insideblock = false;
            }
        }
        else
        {
            if(ch == (int)'{')
            {
                // add the text block before the kanji
                if(kanjiblock > start)
                    AddFragment(fragments, start, kanjiblock - start, StrSplitFuriganaListType::Text);

                // add the kanji block
                assert(kanjiblock >= 0);
                if(kanjiblock >= 0)
                    AddFragment(fragments, kanjiblock, index - kanjiblock, StrSplitFuriganaListType::Kanji);

                // continue the block
                start = index + chsize;
                insideblock = true;
                kanjiblock = -1;
                kanjisize = 0;
            }
            else
            {
                if( kanjiblock < 0 && iskanji(ch) )
                {
                    kanjiblock = index;
                    kanjisize = chsize;
                }
            }
        }

        lastsize = chsize;
        index += chsize;
    }

    assert(!insideblock);

    if(start < textsize)
    {
        // add the text at the end
        AddFragment(fragments, start, textsize - start, StrSplitFuriganaListType::Text);
    }

#ifdef _DEBUG
    // sanity check the data
    int f = 0;
    for(int index = 0; index < textsize; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate(subtitle + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        // check if we are within the fragment
        int start = fragments[f];
        int len = fragments[f+1];
        auto tpe = (StrSplitFuriganaListType) fragments[f+2];

        assert(index >= start && index <= start + len);

        // check if we move to the next fragment
        if(index >= start + len)
        {
            f += 3;
        }
    }
#endif // _DEBUG
}

void StrStripFurigana(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    // check if there are actually furigana in there
    auto textstr = text.c_str();
    const int textsize = (int) text.Length();
    bool hasfurigana = false;
    for(int i = 0; i < textsize; ++i)
    {
        // this is okay because it is an ascii character
        if( textstr[i] == '{' )
        {
            hasfurigana = true;
            break;
        }
    }

    // handle the simple case that there is no furigana
    if(!hasfurigana)
    {
        *aOut = text;
        return;
    }

    vectorstring<char> stripped;
    stripped.reserve(textsize);

    int start = 0;
    for(int i = 1; i < textsize; ++i)
    {
        // this is okay because it is an ascii character
        if( textstr[i] == '{' )
        {
            stripped.addstring(textstr, start, i - 1);
        }
        else if( textstr[i] == '}' )
        {
            start = i + 1;
        }
    }

    if(start < textsize)
    {
        stripped.addstring(textstr, start, textsize - 1);
    }

    stripped.addzero();

    RED4ext::CString result( stripped.data() );

    (*aOut) = std::move(result);
}

void StrFindLastWord(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    int end = -1;
    RED4ext::GetParameter(aFrame, &end);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    const int len = text.Length();

    if(end < 1 || end > len)
        end = len;

    const size_t size = (size_t) end;

    // find the last word
    int lastword = -1;
    for(int index = 0; index < end; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)text.c_str() + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        if(ch == ' ' || ch == '.' || ch == ',' || ch == 0x3002 /*。*/ || ch == 0x3001 /*、*/)
        {
            lastword = index;
        }
    }

    *aOut = lastword;
}

void UnicodeStringLen(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, int* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    const int len = text.Length();

    int count = 0;
    for(int index = 0; index < len; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)text.c_str() + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        count++;
    }

    *aOut = count;
}

#define COPYUNK(name) std::memcpy(&widget1->name, &widget22->name, sizeof(RED4ext::ink::TextWidget::name));

void DebugTextWidget(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, void* aOut, int64_t a4)
{
    RED4ext::Handle<RED4ext::ink::TextWidget> widget1;
    RED4ext::GetParameter(aFrame, &widget1);

    RED4ext::WeakHandle<RED4ext::ink::TextWidget> widget2;
    RED4ext::GetParameter(aFrame, &widget2);
    auto widget22 = widget2.Lock();

    aFrame->code++; // skip ParamEnd

    //COPYUNK(unk254);  // makes it invisible
    //COPYUNK(unk25A);  // makes it invisible
    //COPYUNK(unk280);  // weird invisible
    //COPYUNK(unk2B9);  //
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
        func->SetReturnType("array<Int16>");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("StrStripFurigana", "StrStripFurigana", &StrStripFurigana);
        func->flags = flags;
        func->AddParam("String", "text");
        func->SetReturnType("String");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("StrFindLastWord", "StrFindLastWord", &StrFindLastWord);
        func->flags = flags;
        func->AddParam("String", "text");
        func->AddParam("Int32", "end");
        func->SetReturnType("Int32");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("UnicodeStringLen", "UnicodeStringLen", &UnicodeStringLen);
        func->flags = flags;
        func->AddParam("String", "text");
        func->SetReturnType("Int32");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("DebugTextWidget", "DebugTextWidget", &DebugTextWidget);
        func->flags = flags;
        func->AddParam("ref<inkText>", "widget1");
        func->AddParam("wref<inkText>", "widget2");
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
