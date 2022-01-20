# requires mecab-python3 unidic and pykakasi package
import os, json, MeCab, unidic, pykakasi

from furigana.furigana.furigana import is_kanji, split_furigana, use_pykakasi

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)

def addfurigana(mecab, kana2hiragana, entry, variant):
	if variant not in entry:
		return False

	v = entry[variant]

	# check if there are any kanji
	haskanji = False
	for c in v:
		if is_kanji(c):
			haskanji = True
			break

	if not haskanji:
		return False

	# because of our format, the text cannot contain brackets
	openbracket = "{"
	closebracket = "}"
	assert openbracket not in v and closebracket not in v, "We have to use a different syntax"

	split = split_furigana(v, mecab, kana2hiragana)

	final = ""
	hasfurigana = False
	for s in split:
		if len(s) == 2:
			final += s[0] + openbracket + s[1] + closebracket
			hasfurigana = True
		else:
			final += s[0]

	if hasfurigana:
		entry[variant] = final
		return True

	return False


def processjson(mecab, kana2hiragana, file, jsn):
	print("Processing " + os.path.basename(file) + "...")

	chunks = jsn["Chunks"]

	for c in chunks:
		cc = chunks[c]
		t = cc["Type"]

		if t == "localizationPersistenceSubtitleEntries" and "Properties" in cc:
			props = cc["Properties"]
			entries = props["entries"]

			hasfurigana = False
			for e in entries:
				if addfurigana(mecab, kana2hiragana, e, "femaleVariant"):
					hasfurigana = True
				if addfurigana(mecab, kana2hiragana, e, "maleVariant"):
					hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(mecab, kana2hiragana, path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			process(mecab, kana2hiragana, p)

		elif f.endswith(".json"):
			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(mecab, kana2hiragana, p, jsn)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
mecab = MeCab.Tagger()#"-Ochasen")
mecab.parse('') # 空でパースする必要がある

kana2hiragana = use_pykakasi()

#split = split_furigana("じっとして。やり過ごすの", mecab, kana2hiragana)

process(mecab, kana2hiragana, sourcepath)
