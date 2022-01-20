# requires mecab-python3 and unidic package
import os, sys, shutil, subprocess, json, MeCab, unidic

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"
targetpath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw_Subtitles"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)

def addfurigana(tagger, entry, variant):
	if variant not in entry:
		return False

	v = entry[variant]

	tagged = tagger.parse(v)

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

tagger = MeCab.Tagger()

process(tagger, sourcepath)
