# requires mecab-python3 unidic and pykakasi package
import os, json, MeCab, unidic, pykakasi

from furigana.furigana.furigana import is_kanji, split_okurigana

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"
targetpath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw_Subtitles"

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

	node = tagger.parseToNode(v)
	split = split_furigana(kakasi, node)

	a = 0

	return True


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

			a = 0


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
