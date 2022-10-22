# requires mecab-python3, unidic, pykakasi, jamdict, wheel, jamdict-data package
from furiganamaker import Instance, KanjiReading, WordReading, Problems, has_kanji
import os, sys, shutil, json, MeCab, unidic, pykakasi
import xml.etree.cElementTree as ET
from jamdict import Jamdict

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)

if os.path.isdir(os.path.abspath(sourcepath + "_Subtitles")):
	shutil.rmtree( os.path.abspath(sourcepath + "_Subtitles") )


def addfurigana(instance, entry, variant, stringid, filename, problems):
	if variant not in entry:
		return False

	v = entry[variant]
	if v is None:
		return False

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

		hasfurigana, result = instance.process(t, problems, filename)

		if hasfurigana:
			if fixquotes:
				result = result.replace(replacequotes, escapedquote)

			if fixandchar:
				result = result.replace("§", "&")

			xl.attrib["t"] = stringid + result

			str2 = ET.tostring(xl, encoding="unicode")
			entry[variant] = str2
			return True

		return False

	else:
		hasfurigana, result = instance.process(v, problems, filename)

		if hasfurigana:
			entry[variant] = stringid + result
			return True

		return False


def processjson(instance, file, jsn, problems):
	entries = jsn["Data"]["RootChunk"]["Properties"]["root"]["Data"]["Properties"]["entries"]

	for cc in entries:
		t = cc["Type"]

		if t == "localizationPersistenceSubtitleEntry" and "Properties" in cc:
			props = cc["Properties"]

			hasfurigana = False
			stringid = props["stringId"]
			relstringid = stringid % 4294967296
			hexid = hex(relstringid)[2:].upper()
			if hexid.endswith("000"):
				hexid = hexid[:-3] + "Z"
			strid = hexid + "^"

			if addfurigana(instance, props, "femaleVariant", strid, file, problems):
				hasfurigana = True
			if addfurigana(instance, props, "maleVariant", strid, file, problems):
				hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(instance, path, filen, count, problems):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			filen = process(instance, p, filen, count, problems)

		elif f.endswith(".json"):
			p1 = 10 * filen // count
			filen += 1
			p2 = 10 * filen // count

			if p1 != p2:
				sys.stdout.write(" " + str(p2 * 10) + "%")

			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(instance, p, jsn, problems)

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

# provide additional readings needed by the subtitles
kanjireadings = {
	"応": KanjiReading(("オウ", "ヨウ", "ノウ"), ("あた", "まさに", "こた")),
	"摂": KanjiReading(("セツ", "ショウ"), ("おさ", "かね", "と")),
	"癒": KanjiReading(("ユ",), ("いや", "い")),
	"話": KanjiReading(("ワ",), ("はなし", "はな")),
	"事": KanjiReading(("ジ", "ズ"), ("こと", "ごと", "つか")),
	"通": KanjiReading(("ツウ", "ツ,", "トウ"), ("とお", "どお", "かよ")),
	"間": KanjiReading(("カン", "ケン", "ゲン"), ("あいだ", "あい", "ま")),
	"配": KanjiReading(("ハイ", "パイ"), ("くば",)),
	"発": KanjiReading(("ハツ", "ハッ", "ホツ"), ("はな", "つか", "おこ", "あば", "た")),
	"入": KanjiReading(("ジュ", "ニュウ"), ("はい", "いっ", "い")),
	"結": KanjiReading(("ケチ", "ケツ", "ケッ"), ("むす", "ゆ")),
	"手": KanjiReading(("シュ", "ズ"), ("て", "で", "た")),
	"日": KanjiReading(("ニチ", "ジツ", "ニ"), ("ひ", "び", "か")),
	"真": KanjiReading(("シン",), ("まこと", "ま")),
	"一": KanjiReading(("イチ", "イツ", "イ"), ("ひと", "いっ")),
	"六": KanjiReading(("ロク", "リク"), ("む", "むっ", "むい", "ろっ")),
	"八": KanjiReading(("ハチ", "ハツ"), ("や", "やっ", "よう", "はっ")),
}

# provide readings for kanji words, in case that translation is incorrect
wordreadings = [
	WordReading(("真", "の", "戦", "士"), ("しん", "の", "せん", "し")),
	WordReading(("五", "ヶ", "年"), ("ご", "か", "ねん")),
	WordReading(("五", "ヶ", "月"), ("ご", "か", "げつ")),
	WordReading(("六", "ヶ", "月"), ("ろっ", "か", "げつ")),
	WordReading(("二", "ヶ", "所"), ("に", "か", "しょ")),
]

maker = Instance("{", "}", kakasi, mecab, jam)

maker.add_kanjireadings(kanjireadings)
maker.add_wordreadings(wordreadings)

sys.stdout.write("Processing 0%")
process(maker, sourcepath, 0, count, problems)
sys.stdout.write(" done.\n")

if len(problems) > 0:
	# print 100 problems
	Problems.print_all(problems, 100)

	# sort problems by kanji
	sort = Problems.print_kanjiproblems_list(problems)

	# show top problems
	k = sort[0][0]
	Problems.print_kanjiproblems(problems, k, 10)
