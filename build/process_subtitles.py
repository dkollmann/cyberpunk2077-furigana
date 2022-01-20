# requires mecab-python3 unidic and pykakasi package
import os, json, MeCab, unidic, pykakasi

from furigana.furigana.furigana import is_kanji, split_okurigana

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
def split_furigana(kakasi, node):
	ret = []

	while node is not None:
		origin = node.surface # もとの単語を代入
		if not origin:
			node = node.next
			continue

		# originが空のとき、漢字以外の時はふりがなを振る必要がないのでそのまま出力する
		if origin != "" and any(is_kanji(_) for _ in origin):
			#sometimes MeCab can't give kanji reading, and make node-feature have less than 7 when splitted.
			#bypass it and give kanji as isto avoid IndexError
			split = node.feature.split(",")
			if len(split) > 7:
				kana = split[7] # 読み仮名を代入
			else:
				kana = node.surface
			#hiragana = jaconv.kata2hira(kana)
			conv = kakasi.convert(kana)
			hiragana = conv[0]["hira"]
			for pair in split_okurigana(origin, hiragana):
				ret += [pair]
		else:
			if origin:
				ret += [(origin,)]
		node = node.next
	return ret


def addfurigana(tagger, kakasi, entry, variant):
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

	node = tagger.parseToNode(v)
	split = split_furigana(kakasi, node)

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


def processjson(tagger, kakasi, file, jsn):
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
				if addfurigana(tagger, kakasi, e, "femaleVariant"):
					hasfurigana = True
				if addfurigana(tagger, kakasi, e, "maleVariant"):
					hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(tagger, kakasi, path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			process(tagger, kakasi, p)

		elif f.endswith(".json"):
			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(tagger, kakasi, p, jsn)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
tagger = MeCab.Tagger()#"-Ochasen")
tagger.parse('') # 空でパースする必要がある

kakasi = pykakasi.kakasi()

process(tagger, kakasi, sourcepath)
