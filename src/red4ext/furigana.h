#pragma once

#include "RED4ext/DynArray.hpp"


enum class StrSplitFuriganaListType : short
{
    NoBlock = -1,
    Text = 0,
    Kanji = 1,
    Furigana = 2,
    Katakana = 3,
    Latin = 4
};

enum class StrSplitFuriganaIndex : int
{
    Start = 0,
    Size = 1,
    CharCount = 2,
    Type = 3,
    COUNT = 4
};

enum class StrSplitFuriganaKatakanaMode : int
{
    Disabled = 0,
    Enabled = 1,

    IncludeLatin = 2,
    IncludeNumbers = 4
};

typedef RED4ext::DynArray<short> StrSplitFuriganaList;

extern void ParseFurigana(const char8_t *textstr, int textsize, int katakanamode, StrSplitFuriganaList &fragments);
