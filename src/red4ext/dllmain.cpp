#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <shellapi.h>
#include <RED4ext/RED4ext.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/TextWidget.hpp>
#include "utf8proc/utf8proc.h"
#include <vector>
#include <assert.h>
#include <charconv>

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

static const int JapaneseSpace = 0x3000; /*　*/
static const int JapaneseDot   = 0x3002; /*。*/
static const int JapaneseComma = 0x3001; /*、*/
static const int JapaneseExclamationMark = 0xFF01; /*！*/
static const int JapaneseQuestionMark    = 0xFF1F; /*？*/

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

constexpr bool iskanji(int n)
{
    // must be the same as from the python script that generates the furigana
    return (n >= 19968 && n <= 40959) || n == 12293 || n == 12534;
}

constexpr bool iskatakana(int n)
{
    return (n >= 12448 && n <= 12543);
}

enum class StrSplitFuriganaListType : short
{
    Text = 0,
    Kanji = 1,
    Furigana = 2,
    Katakana = 3
};

typedef RED4ext::DynArray<short> StrSplitFuriganaList;

enum class StrSplitFuriganaIndex : int
{
    Start = 0,
    Size = 1,
    CharCount = 2,
    Type = 3,
    COUNT = 4
};

void AddFragment(StrSplitFuriganaList &fragments, int start, int size, int charcount, StrSplitFuriganaListType type)
{
    assert(start >= 0);
    assert(size > 0);
    assert(charcount > 0 && charcount <= size);

    fragments.PushBack((short)start);
    fragments.PushBack((short)size);
    fragments.PushBack((short)charcount);
    fragments.PushBack((short)type);
}

void StrAddSpaces(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    auto textstr = text.c_str();
    const int len = text.Length();

    // check if we will add spaces
    bool needspaces = false;
    for(int index = 0; index < len; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)textstr + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        // there is no point of adding a space at the end
        if(index == len)
            break;

        if(ch == JapaneseComma || ch == JapaneseDot)
        {
            needspaces = true;
            break;
        }
    }

    if(!needspaces)
    {
        // just return the string as it is
        *aOut = text;
        return;
    }

    // add the actual spaces
    std::vector<char> str;
    str.resize(len);

    std::memcpy(str.data(), textstr, len);

    for(size_t index = 0; index < str.size(); )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)str.data() + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        // there is no point of adding a space at the end
        if(index == str.size())
            break;

        if(ch == JapaneseComma || ch == JapaneseDot || ch == JapaneseExclamationMark || ch == JapaneseQuestionMark)
        {
            // insert a space
            str.insert(str.begin() + index, { (char)0xE3, (char)0x80, (char)0x80 });

            index += 3;
        }
    }

    str.push_back(0);

    RED4ext::CString str2(str.data());

    *aOut = std::move(str2);
}


int FindStringIdEnd(const char *text)
{
    for(int i = 0; i < 17; ++i)
    {
        if( text[i] == '^' )
            return i + 1;
    }

    return 0;
}


void StrSplitFurigana(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, StrSplitFuriganaList* aOut, int64_t a4)
{
    RED4ext::CString text;
    RED4ext::GetParameter(aFrame, &text);

    bool dokatakana = false;
    RED4ext::GetParameter(aFrame, &dokatakana);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    StrSplitFuriganaList &fragments = *aOut;

    // check if there are actually furigana in there
    auto textstr = text.c_str();
    const int textsize = (int) text.Length();
    const int stringidend = FindStringIdEnd(textstr);
    bool hasfurigana = false;
    bool haskatakana = false;

    {
        int charcount = 0;
        for(int index = stringidend; index < textsize; )
        {
            utf8proc_int32_t ch;
            const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)textstr + index, -1, &ch);

            if(chsize <= 0)
                break;

            index += chsize;
            charcount++;

            if( ch == '{' )
            {
                hasfurigana = true;

                if(hasfurigana && haskatakana)
                    break;
            }

            else if( dokatakana && iskatakana(ch) )
            {
                haskatakana = true;

                if(hasfurigana && haskatakana)
                    break;
            }
        }

        // handle the simple case that there is no furigana
        if(!hasfurigana && !haskatakana)
        {
            AddFragment(fragments, stringidend, textsize - stringidend, charcount, StrSplitFuriganaListType::Text);
            return;
        }
    }

    fragments.Reserve(128);

    int start = stringidend;
    int charcount = 0;
    int kanjiblock = -1;
    int kanjiblock_charcount = 0;
    int kanjisize = 0;
    int katakanablock = -1;
    int katakanablock_charcount = 0;
    bool insideblock = false;

    auto subtitle = (const utf8proc_uint8_t*) textstr;
    for(int index = stringidend; index < textsize; )
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
                AddFragment(fragments, start, index - start, charcount, StrSplitFuriganaListType::Furigana);

                // continue outside of the block
                start = index + chsize;
                charcount = 0;
                insideblock = false;
            }
            else
            {
                charcount++;
            }
        }
        else
        {
            if(hasfurigana && ch == (int)'{')
            {
                // add the text block before the kanji
                if(kanjiblock > start)
                {
                    AddFragment(fragments, start, kanjiblock - start, charcount, StrSplitFuriganaListType::Text);
                    charcount = 0;
                }

                // add the kanji block
                assert(kanjiblock >= 0);
                if(kanjiblock >= 0)
                {
                    AddFragment(fragments, kanjiblock, index - kanjiblock, kanjiblock_charcount, StrSplitFuriganaListType::Kanji);
                    kanjiblock_charcount = 0;
                    kanjiblock = -1;
                }

                // continue the block
                start = index + chsize;
                insideblock = true;
                kanjisize = 0;
            }
            else
            {
                if( kanjiblock < 0 && iskanji(ch) )
                {
                    kanjiblock = index;
                    kanjisize = chsize;
                    assert(kanjiblock_charcount == 0);
                }

                // handle extracting katakana
                bool iskata = false;
                if(haskatakana)
                {
                    if( iskatakana(ch) )
                    {
                        iskata = true;

                        if(katakanablock < 0)
                        {
                            katakanablock = index;

                            // add the text before the katakana
                            if(katakanablock > start)
                            {
                                AddFragment(fragments, start, katakanablock - start, charcount, StrSplitFuriganaListType::Text);
                                charcount = 0;
                            }
                        }

                        katakanablock_charcount++;
                    }
                    else
                    {
                        if(katakanablock >= 0)
                        {
                            AddFragment(fragments, katakanablock, index - katakanablock, katakanablock_charcount, StrSplitFuriganaListType::Katakana);

                            start = index;
                            katakanablock = -1;
                            katakanablock_charcount = 0;
                        }
                    }
                }

                if(!iskata)
                {
                    if(kanjiblock >= 0)
                        kanjiblock_charcount++;
                    else
                        charcount++;
                }
            }
        }

        index += chsize;
    }

    assert(!insideblock);

    if(start < textsize)
    {
        // add the text at the end
        if(katakanablock >= 0)
            AddFragment(fragments, katakanablock, textsize - katakanablock, katakanablock_charcount, StrSplitFuriganaListType::Katakana);
        else
            AddFragment(fragments, start, textsize - start, charcount, StrSplitFuriganaListType::Text);
    }

#ifdef _DEBUG
    // sanity check the data
    unsigned int f = 0;
    int testcount = 0;
    for(int index = stringidend; index < textsize && f < fragments.size; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate(subtitle + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        if(ch == (int)'{' || ch == (int)'}')
            continue;

        testcount++;

        // check if we are within the fragment
        int start = fragments[f + (int)StrSplitFuriganaIndex::Start];
        int sz = fragments[f + (int)StrSplitFuriganaIndex::Size];
        int count = fragments[f + (int)StrSplitFuriganaIndex::CharCount];
        auto tpe = (StrSplitFuriganaListType) fragments[f + (int)StrSplitFuriganaIndex::Type];

        assert(index >= start && index <= start + sz);

        // check if we move to the next fragment
        if(index >= start + sz)
        {
            assert(index == start + sz);
            assert(count == testcount);
            testcount = 0;

            f += (int)StrSplitFuriganaIndex::COUNT;

            if(f < fragments.size)
            {
                int start2 = fragments[f + (int)StrSplitFuriganaIndex::Start];
                assert(start2 == index || start2 == index + 1);  // next character could be { or }
            }
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
    const int stringidend = FindStringIdEnd(textstr);
    bool hasfurigana = false;
    for(int i = stringidend; i < textsize; ++i)
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

    int start = stringidend;
    for(int i = stringidend; i < textsize; ++i)
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

    int desiredlength = -1;
    RED4ext::GetParameter(aFrame, &desiredlength);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    auto textstr = text.c_str();
    const int len = text.Length();

    if(desiredlength < 1 || desiredlength > len)
        desiredlength = len;

    const size_t size = (size_t) desiredlength;

    // find the last word
    int lastword = -1;
    for(int index = 0; index < len; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)textstr + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        if( ch == ' ' || ch == '.' || ch == ',' || ch == '!' || ch == '?' ||
            ch == JapaneseSpace || ch == JapaneseDot || ch == JapaneseComma || ch == JapaneseExclamationMark || ch == JapaneseQuestionMark )
        {
            if(index < desiredlength)
            {
                lastword = index;
            }
            else
            {
                // if we are past the desired length, take the first word be can find
                if(lastword < 0)
                    lastword = index;

                break;
            }
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

    auto textstr = text.c_str();
    const int len = text.Length();

    int count = 0;
    for(int index = 0; index < len; )
    {
        // get the next character
        utf8proc_int32_t ch;
        const int chsize = (int) utf8proc_iterate((const utf8proc_uint8_t*)textstr + index, -1, &ch);

        if(chsize <= 0)
            break;

        index += chsize;

        count++;
    }

    *aOut = count;
}

void CRUIDToUint64(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, uint64_t* aOut, int64_t a4)
{
    RED4ext::CRUID id;
    RED4ext::GetParameter(aFrame, &id);

    aFrame->code++; // skip ParamEnd

    // if the result cannot be stored, there is no point of doing this
    if(aOut == nullptr)
        return;

    *aOut = id.unk00;
}

void OpenBrowser(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, uint64_t* aOut, int64_t a4)
{
    RED4ext::CString url;
    RED4ext::GetParameter(aFrame, &url);

    aFrame->code++; // skip ParamEnd

    ShellExecuteA(NULL, "open", url.c_str(), NULL, NULL, SW_SHOWNORMAL);
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
        auto func = RED4ext::CGlobalFunction::Create("StrAddSpaces", "StrAddSpaces", &StrAddSpaces);
        func->flags = flags;
        func->AddParam("String", "text");
        func->SetReturnType("String");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("StrSplitFurigana", "StrSplitFurigana", &StrSplitFurigana);
        func->flags = flags;
        func->AddParam("String", "text");
        func->AddParam("Bool", "splitKatakana");
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
        auto func = RED4ext::CGlobalFunction::Create("CRUIDToUint64", "CRUIDToUint64", &CRUIDToUint64);
        func->flags = flags;
        func->AddParam("CRUID", "id");
        func->SetReturnType("Uint64");
        rtti->RegisterFunction(func);
    }

    {
        auto func = RED4ext::CGlobalFunction::Create("OpenBrowser", "OpenBrowser", &OpenBrowser);
        func->flags = flags;
        func->AddParam("String", "url");
        func->SetReturnType("Void");
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
