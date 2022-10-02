#ifdef _DEBUG

#include "furigana.h"
#include <cassert>

void ParseFurigana(const char8_t *textstr, int katakanamode, StrSplitFuriganaList &fragments)
{
	ParseFurigana(textstr, std::strlen((const char*)textstr), katakanamode, fragments);
}

void CheckFragment(const char8_t *text, const StrSplitFuriganaList &fragments, int index, const char8_t *expected, StrSplitFuriganaListType etype)
{
	index *= (int) StrSplitFuriganaIndex::COUNT;

	int start = fragments[index + (int)StrSplitFuriganaIndex::Start];
	int sz = fragments[index + (int)StrSplitFuriganaIndex::Size];
	int count = fragments[index + (int)StrSplitFuriganaIndex::CharCount];
	auto tpe = (StrSplitFuriganaListType) fragments[index + (int)StrSplitFuriganaIndex::Type];

	int esz = std::strlen((const char*)expected);

	assert(sz == esz);
	assert(tpe == etype);

	std::vector<char8_t> buf;
	buf.resize(sz + 1);
	buf[sz] = 0;

	std::memcpy(buf.data(), text + start, sz);

	assert( std::memcmp(buf.data(), expected, sz) == 0 );
}

void RunUnitTests()
{
	constexpr int katakanamode = (int)StrSplitFuriganaKatakanaMode::Enabled | (int)StrSplitFuriganaKatakanaMode::IncludeLatin | (int)StrSplitFuriganaKatakanaMode::IncludeNumbers;

	char8_t buf[1024];

	{
		auto str = u8"煙の立つところに、バーガスあり";
		StrSplitFuriganaList f;
		ParseFurigana(str, katakanamode, f);

		assert(f.size == 6 * (int) StrSplitFuriganaIndex::COUNT);

		CheckFragment(str, f, 0, u8"煙", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 1, u8"の", StrSplitFuriganaListType::Text);
		CheckFragment(str, f, 2, u8"立", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 3, u8"つところに、", StrSplitFuriganaListType::Text);
		CheckFragment(str, f, 4, u8"バーガス", StrSplitFuriganaListType::Katakana);
		CheckFragment(str, f, 5, u8"あり", StrSplitFuriganaListType::Text);
	}

	{
		auto str = u8"682C5004^人{じん}生{せい}で一{いち}番{ばん}大{たい}切{せつ}なことは何{なに}？";
		StrSplitFuriganaList f;
		ParseFurigana(str, katakanamode, f);

		assert(f.size == 17 * (int) StrSplitFuriganaIndex::COUNT);

		CheckFragment(str, f, 0, u8"人", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 1, u8"じん", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 2, u8"生", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 3, u8"せい", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 4, u8"で", StrSplitFuriganaListType::Text);
		CheckFragment(str, f, 5, u8"一", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 6, u8"いち", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 7, u8"番", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 8, u8"ばん", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 9, u8"大", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 10, u8"たい", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 11, u8"切", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 12, u8"せつ", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 13, u8"なことは", StrSplitFuriganaListType::Text);
		CheckFragment(str, f, 14, u8"何", StrSplitFuriganaListType::Kanji);
		CheckFragment(str, f, 15, u8"なに", StrSplitFuriganaListType::Furigana);
		CheckFragment(str, f, 16, u8"？", StrSplitFuriganaListType::Text);
	}
}

#endif
