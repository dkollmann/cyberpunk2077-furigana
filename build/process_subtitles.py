# requires mecab-python3, unidic and pykakasi package
import os, json, unicodedata, MeCab, unidic, pykakasi
import xml.etree.cElementTree as ET

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)


def is_kanji(ch):
	return 'CJK UNIFIED IDEOGRAPH' in unicodedata.name(ch)


def addfurigana_text(mecab, kakasi, text):
	# because of our format, the text cannot contain brackets
	openbracket = "{"
	closebracket = "}"
	assert openbracket not in text and closebracket not in text, "We have to use a different syntax"

	node = mecab.parseToNode(text)

	str = ""
	hasfurigana = False
	while node is not None:
		if len(node.surface) > 0:
			conv = kakasi.convert(node.surface)

			for c in conv:
				orig = c["orig"]
				hira = c["hira"]

				if orig != hira:
					hasfurigana = True

					# find start and end
					for a in range(len(orig)):
						if orig[a] != hira[a]:
							break

					b = 0
					for b in range(-1, -len(orig), -1):
						if orig[b] != hira[b]:
							break

					if a > 0 and b < 0:
						hiragana = hira[a:b]
					else:
						hiragana = hira

					str += orig[:a + 1] + openbracket + hiragana + closebracket + orig[b:]
				else:
					str += orig

		node = node.next

	return (hasfurigana, str)


def addfurigana(mecab, kakasi, entry, variant):
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

	# detect xml
	if v.startswith("<") and v.endswith("/>"):
		xl = ET.fromstring(v)
		t = xl.attrib["t"]

		hasfurigana, str = addfurigana_text(mecab, kakasi, t)

		if hasfurigana:
			xl.attrib["t"] = str

			str2 = ET.tostring(xl, encoding="unicode")
			entry[variant] = str2
			return True

		return False

	hasfurigana, str = addfurigana_text(mecab, kakasi, v)

	if hasfurigana:
		entry[variant] = str
		return True

	return False


def processjson(mecab, kakasi, file, jsn):
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
				if addfurigana(mecab, kakasi, e, "femaleVariant"):
					hasfurigana = True
				if addfurigana(mecab, kakasi, e, "maleVariant"):
					hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(mecab, kakasi, path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			process(mecab, kakasi, p)

		elif f.endswith(".json"):
			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(mecab, kakasi, p, jsn)


# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
mecab = MeCab.Tagger()  #"-Ochasen"
kakasi = pykakasi.kakasi()

process(mecab, kakasi, sourcepath)
