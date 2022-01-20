# requires mecab-python3 unidic and jaconv package
import os, json, MeCab, unidic, jaconv

from furigana.furigana.furigana import is_kanji, split_okurigana

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"
targetpath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw_Subtitles"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
def split_furigana(node):
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
			hiragana = jaconv.kata2hira(kana)
			for pair in split_okurigana(origin, hiragana):
				ret += [pair]
		else:
			if origin:
				ret += [(origin,)]
		node = node.next
	return ret


def addfurigana(tagger, entry, variant):
	if variant not in entry:
		return False

	v = entry[variant]

	node = tagger.parseToNode(v)
	split = split_furigana(node)

	a = 0

	return True


def processjson(tagger, file, jsn):
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
				if addfurigana(tagger, e, "femaleVariant"):
					hasfurigana = True
				if addfurigana(tagger, e, "maleVariant"):
					hasfurigana = True

			a = 0


def process(tagger, path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			process(tagger, p)

		elif f.endswith(".json"):
			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(tagger, p, jsn)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
tagger = MeCab.Tagger()#"-Ochasen")
tagger.parse('') # 空でパースする必要がある

process(tagger, sourcepath)
