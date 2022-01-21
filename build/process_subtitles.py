# requires mecab-python3, unidic, pykakasi, jamdict, wheel, jamdict-data package
import os, sys, shutil, json, unicodedata, MeCab, unidic, pykakasi
import xml.etree.cElementTree as ET
from jamdict import Jamdict

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)

if os.path.isdir(os.path.abspath(sourcepath + "_Subtitles")):
	shutil.rmtree( os.path.abspath(sourcepath + "_Subtitles") )


def is_kanji(ch):
	return ('CJK UNIFIED IDEOGRAPH' in unicodedata.name(ch)) or ch == '々' or ch == 'ヶ'


def has_kanji(str):
	for c in str:
		if is_kanji(c):
			return True

	return False


def all_kanji(str):
	for c in str:
		if not is_kanji(c):
			return False

	return True


def kana2hira(processdata, kana):
	conv = processdata.kakasi.convert(kana)

	hira = ""
	for c in conv:
		hira += c["hira"]

	assert len(kana) == len(hira), "Expected both to be the same length"

	return hira


def hira2kana(processdata, hira):
	conv = processdata.kakasi.convert(hira)

	kana = ""
	for c in conv:
		kana += c["kana"]

	assert len(kana) == len(hira), "Expected both to be the same length"

	return kana


def has_reading_kana(readings, newkana):
	for r in readings:
		if r[0] == newkana:
			return True

	return False


def has_reading_hira(readings, newhira):
	for r in readings:
		if r[1] == newhira:
			return True

	return False


def get_kanjireading(processdata, katakana, kanji):
	if kanji in processdata.readingscache:
		return processdata.readingscache[kanji]

	foundreadings = []

	# check jamkit
	if processdata.jam is not None:
		data = processdata.jam.lookup(kanji, strict_lookup=True, lookup_ne=False)
		if len(data.chars) > 0:
			assert len(data.chars) == 1
			assert len(data.chars[0].rm_groups) == 1

			on_readings = data.chars[0].rm_groups[0].on_readings
			for r in on_readings:
				k = r.value

				if not has_reading_kana(foundreadings, k):
					h = kana2hira(processdata, k)

					foundreadings.append( (k, h) )

			kun_readings = data.chars[0].rm_groups[0].kun_readings
			for r in kun_readings:
				h = r.value.lstrip("-")

				dot = h.find(".")
				if dot >= 0:
					h = h[:dot]

				if not has_reading_hira(foundreadings, h):
					k = hira2kana(processdata, h)

					foundreadings.append((k, h))

	# check mecab
	if processdata.mecab is not None:
		node = processdata.mecab.parseToNode(kanji + "一")  # this is a hack to get the Chinese reading
		while node:
			if len(node.surface) > 0:
				sp = node.feature.split(",")
				if len(sp) >= 7:
					kana = sp[6]

					# when the kana is the whole word, skip it
					if len(kana) != len(katakana) and not has_reading_kana(foundreadings, kana):
						hira = kana2hira(processdata, kana)

						foundreadings.append(( kana, hira) )

				node = node.bnext
			else:
				node = node.next

	processdata.readingscache[kanji] = foundreadings

	return foundreadings


kanjinumbers = ("一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "零")


def find_reading(processdata, kanji, katakana, readings, filename):
	showproblem = True

	# check if this is a number
	if len(kanji) == 2 and kanji[0] in kanjinumbers:
		showproblem = False

	# check if this is a "saying"
	if len(kanji) == 2 and kanji[1] == "々":
		return False

	# get all the readings for the kanji
	katakanaleft = katakana

	for k in kanji:
		found = False

		# check if we have an additional reading for this
		foundreadings = get_kanjireading(processdata, katakana, k)

		# check if we found something
		if len(foundreadings) < 1:
			processdata.addproblem(filename, "Failed to find any reading for \"" + k + "\".", k)
			return False

		# try to match the kanji with the reading
		for kana, hira in foundreadings:
			if katakanaleft.startswith(kana):
				found = True
				readings.append(hira)
				katakanaleft = katakanaleft[len(kana):]
				break

		# when one kanji fails we have to abort
		if not found:
			if showproblem:
				processdata.addproblem(filename, "Could not match kanji \"" + k + "\" to kana \"" + katakanaleft + "\".", k)
			return False

	# check if all of the reading was "consumed"
	if len(katakanaleft) > 0:
		processdata.addproblem(filename, "Matched all kanji of \"" + kanji + "\" to \"" + katakana + "\" but \"" + katakanaleft + "\" was left over.", kanji)
		return False

	assert len(readings) > 0, "There should be readings here"
	return True


def split_kanji(kanji):
	result = []

	start = 0
	waskanji = is_kanji(kanji[0])

	i = 1
	while i < len(kanji):
		k = kanji[i]
		iskanji = is_kanji(k)

		if waskanji != iskanji:
			kk = kanji[start:i]
			result.append( (kk, waskanji) )

			start = i
			waskanji = iskanji

		i += 1

	if start < len(kanji):
		kk = kanji[start:]
		result.append((kk, waskanji))

	return result


def split_katakana(hiraganasplit, katakana):
	# sanity check first
	ln = 0
	for t, ik in hiraganasplit:
		ln += len(t)
	assert ln == len(katakana), "The hiragana and the katakana must be the same length"

	# apply the same split to the katakana
	result = []
	start = 0
	for t, ik in hiraganasplit:
		k = katakana[start:len(t)]
		result.append( (k, ik) )
		start = len(t)

	assert len(result) == len(hiraganasplit), "Both splits must have the same length"

	return result


basehiragana = {
	"が": "か", "ざ": "さ", "だ": "た", "ば": "は", "ぱ": "は",
	"ぎ": "き", "じ": "し", "ぢ": "ち", "び": "ひ", "ぴ": "ひ",
	"ぐ": "く", "ず": "す", "づ": "つ", "ぶ": "ふ", "ぷ": "ふ",
	"げ": "け", "ぜ": "せ", "で": "て", "べ": "へ", "ぺ": "へ",
	"ご": "こ", "ぞ": "そ", "ど": "と", "ぼ": "ほ", "ぽ": "ほ"
}


def split_hiragana(kanjisplit, hiragana, katakana):
	result = []

	# the conversion to hiragana will also convert any katakana, so we have to reverse this
	assert len(hiragana) == len(katakana), "Expected both to be the same length"

	# we get better results when matching the hiragana from back to start
	end = len(hiragana)
	endfind = end
	for i in range(len(kanjisplit)):
		e = kanjisplit[ len(kanjisplit) - i - 1 ]

		# ignore kanji elements
		if e[1]:
			endfind -= 1
			continue

		# try to find the non-kanji text
		t = e[0]
		text = hiragana
		pos = hiragana.rfind(t, 0, endfind)

		# handle the case that the pronunciation of a character was changed
		if pos < 0 and len(t) == 1 and t in basehiragana:
			t2 = basehiragana[t]
			pos = hiragana.rfind(t2, 0, endfind)
			# todo should 'e' be updated to have the hiragana pronunciation?

		# check if this is a unwanted katakana conversion
		if pos < 0:
			text = katakana
			pos = katakana.rfind(t, 0, endfind)

		assert pos >= 0, "Failed to find hiragana"

		start = pos + len(t)
		if start < end:
			kanji = text[start:end]
			result.append( (kanji, True) )

		result.append(e)
		end = pos
		endfind = end

	if end >= 0:
		kanji = hiragana[:end]

		result.append( (kanji, True) )

	result.reverse()

	# sanity check results
	assert len(kanjisplit) == len(result), "Both splits must be the same length"
	for i in range(len(kanjisplit)):
		assert kanjisplit[i][1] == result[i][1], "The type of elements must be the same"

		if not kanjisplit[i][1]:
			assert kanjisplit[i][0] == result[i][0], "Non-kanji elements must be the same"

	return result


def katakana_vowels_init():
	result = {}

	vowels = {
		"ア": ("ア", "カ", "サ", "タ", "ナ", "ハ", "マ", "ヤ", "ラ", "ワ", "ガ", "ザ", "ダ", "バ", "パ", "ャ"),
		"イ": ("イ", "キ", "シ", "チ", "ニ", "ヒ", "ミ", "リ", "ヰ", "ギ", "ジ", "ヂ", "ビ", "ピ"),
		"ウ": ("ウ", "ク", "ス", "ツ", "ヌ", "フ", "ム", "ユ", "ル", "グ", "ズ", "ヅ", "ブ", "プ", "ュ"),
		"エ": ("エ", "ケ", "セ", "テ", "ネ", "ヘ", "メ", "レ", "ヱ", "ゲ", "ゼ", "デ", "ベ", "ペ"),
		"オ": ("オ", "コ", "ソ", "ト", "ノ", "ホ", "モ", "ヨ", "ロ", "ヲ", "ゴ", "ゾ", "ド", "ボ", "ポ", "ョ")
	}

	for v in vowels:
		for k in vowels[v]:
			result[ ord(k) ] = v

	return result


katakana_vowels = katakana_vowels_init()


def fix_longvowels(original, katakana):
	# when the original string uses a 'ー' character, it is lost during the conversion to katakana, so we restore it
	pos = original.find("ー")

	while pos > 0:
		# determine the vowel which is represented
		vowel = original[pos-1:pos]
		vowel_ord = ord(vowel)

		if vowel_ord in katakana_vowels:
			vowel2 = katakana_vowels[vowel_ord]

			# find the occurence and replace it
			katakana = katakana.replace(vowel + vowel2, vowel + "ー")

		pos = original.find("ー", pos + 1)

	return katakana


def addfurigana_text(processdata, text, filename):
	# because of our format, the text cannot contain brackets
	openbracket = "{"
	closebracket = "}"
	assert openbracket not in text and closebracket not in text, "We have to use a different syntax"

	str = ""
	hasfurigana = False
	conv = kakasi.convert(text)

	for c in conv:
		orig = c["orig"]
		hira = c["hira"]
		kana = c["kana"]

		assert len(hira) == len(kana), "Expected both to be the same length"

		# handle the case of an untranslated kanji
		if len(hira) < 1:
			processdata.addproblem(filename, "Failed to translate '" + orig + "'.")
			continue

		# ignore any conversion other than kanji
		if not has_kanji(orig) or orig == hira:
			str += orig
			continue

		hasfurigana = True

		# find the kanji blocks
		split_kanjis = split_kanji(orig)

		if len(split_kanjis) > 1:
			kana = fix_longvowels(orig, kana)

			split_hira = split_hiragana(split_kanjis, hira, kana)
			split_kana = split_katakana(split_hira, kana)
		else:
			assert split_kanjis[0][1], "This must be a kanji element"
			split_hira = [ (hira, True) ]
			split_kana = [ (kana, True) ]

		# for each kanji block, try to match the individual hiragana
		s = ""
		for i in range(len(split_kanjis)):
			kanji = split_kanjis[i][0]
			iskanji = split_kanjis[i][1]
			hiragana = split_hira[i][0]
			katakana = split_kana[i][0]

			matchedkana = False

			# check if matching needs to happen
			if iskanji:
				if len(katakana) > 1:
					readings = []
					matchedkana = find_reading(processdata, kanji, katakana, readings, filename)

				if matchedkana:
					for k in range(len(kanji)):
						s += kanji[k] + openbracket + readings[k] + closebracket
				else:
					s += kanji + openbracket + hiragana + closebracket

			else:
				s += kanji

		str += s

	return (hasfurigana, str)


def addfurigana(processdata, entry, variant, filename):
	if variant not in entry:
		return False

	v = entry[variant]

	# check if there are any kanji
	if not has_kanji(v):
		return False

	# detect xml
	if v.startswith("<") and v.endswith("/>"):
		escapedquote = "\\\""
		replacequotes = "$€"
		fixquotes = escapedquote in v
		fixandchar = "&" in v

		if fixquotes:
			assert replacequotes not in v, "Use a different replacement"

			v = v.replace(escapedquote, replacequotes)

		if fixandchar:
			assert "§" not in v, "Use a different replacement"

			v = v.replace("&", "§")

		xl = ET.fromstring(v)
		t = xl.attrib["t"]

		hasfurigana, str = addfurigana_text(processdata, t, filename)

		if hasfurigana:
			if fixquotes:
				str = str.replace(replacequotes, escapedquote)

			if fixandchar:
				str = str.replace("§", "&")

			xl.attrib["t"] = str

			str2 = ET.tostring(xl, encoding="unicode")
			entry[variant] = str2
			return True

		return False

	else:
		hasfurigana, str = addfurigana_text(processdata, v, filename)

		if hasfurigana:
			entry[variant] = str
			return True

		return False


def processjson(processdata, file, jsn):
	chunks = jsn["Chunks"]

	for c in chunks:
		cc = chunks[c]
		t = cc["Type"]

		if t == "localizationPersistenceSubtitleEntries" and "Properties" in cc:
			props = cc["Properties"]
			entries = props["entries"]

			hasfurigana = False
			for e in entries:
				if addfurigana(processdata, e, "femaleVariant", file):
					hasfurigana = True
				if addfurigana(processdata, e, "maleVariant", file):
					hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(processdata, path, filen, count):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			filen = process(processdata, p, filen, count)

		elif f.endswith(".json"):
			p1 = 10 * filen // count
			filen += 1
			p2 = 10 * filen // count

			if p1 != p2:
				sys.stdout.write(" " + str(p2 * 10) + "%")

			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(processdata, p, jsn)

	return filen

def countfiles(path):
	count = 0

	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			count += countfiles(p)

		elif f.endswith(".json"):
			count += 1

	return count


mecab = MeCab.Tagger()
kakasi = pykakasi.kakasi()
jam = Jamdict()

count = countfiles(sourcepath)
problems = []

# when no reading can be found, we try to use one of these readings instead
additionalreadings = {
	"応": (("オウ", "ヨウ", "ノウ"), ("あた", "まさに", "こた")),
	"摂": (("セツ", "ショウ"), ("おさ", "かね", "と")),
	"癒": (("ユ",), ("いや", "い")),
	"話": (("ワ",), ("はなし", "はな")),
	"事": (("ジ", "ズ"), ("こと", "ごと", "つか")),
	"通": (("ツウ", "ツ,", "トウ"), ("とお", "どお", "かよ"))
}

class ProcessData:
	def __init__(self, mecab, kakasi, jam, additionalreadings, problems):
		self.mecab = mecab
		self.kakasi = kakasi
		self.jam = jam
		self.readingscache = {}
		self.problems = problems

		for r in additionalreadings:
			addk, addh = additionalreadings[r]

			cached = []

			if addk:
				for k in addk:
					h = kana2hira(self, k)

					cached.append( (k, h) )

			if addh:
				for h in addh:
					k = hira2kana(self, h)

					cached.append((k, h))

			self.readingscache[r] = cached

	def addproblem(self, filename, text, kanji=None):
		self.problems.append( (filename, text, kanji) )

sys.stdout.write("Processing 0%")
process(ProcessData(mecab, kakasi, jam, additionalreadings, problems), sourcepath, 0, count)
sys.stdout.write(" done.\n")

if len(problems) > 0:
	# print 100 problems
	for i in range( min(100, len(problems)) ):
		p = problems[i]
		print( p[0] + ": " + p[1])
	print("Found " + str(len(problems)) + " problems...")

	# sort problems by kanji
	counted = {}
	for p in problems:
		kanji = p[2]
		if kanji is not None:
			if kanji in counted:
				counted[kanji] += 1
			else:
				counted[kanji] = 1
	sort = sorted(counted.items(), key=lambda x: x[1], reverse=True)
	sys.stdout.write("Issues: ")
	for k, n in sort:
		sys.stdout.write(k + ": " + str(n) + ", ")
	print(".")
	# show top problems
	k = sort[0][0]
	i = 0
	for p in problems:
		kanji = p[2]
		if kanji == k:
			i += 1
			print(p[0] + ": " + p[1])
			if i >= 10:
				break
