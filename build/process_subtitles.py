# requires mecab-python3, unidic and pykakasi package
import os, json, unicodedata, MeCab, unidic, pykakasi
import shutil
import xml.etree.cElementTree as ET

sourcepath = "../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw"

if not os.path.isfile( os.path.join(unidic.DICDIR, "matrix.bin")):
	print("You have to run as admin: python -m unidic download")
	exit(100)

if os.path.isdir(os.path.abspath(sourcepath + "_Subtitles")):
	shutil.rmtree( os.path.abspath(sourcepath + "_Subtitles") )


def is_kanji(ch):
	return 'CJK UNIFIED IDEOGRAPH' in unicodedata.name(ch)


def has_kanji(str):
	for c in str:
		if is_kanji(c):
			return True

	return False


def find_reading(mecab, kakasi, kanji, furigana, readings):
	# get katakana reading
	katakana = kakasi.convert(furigana)[0]["kana"]

	# get all the readings for the kanji
	katakanaleft = katakana

	for k in kanji:
		features = []
		node = mecab.parseToNode(k + "一")  # this is a hack to get the Chinese reading
		while node:
			if len(node.surface) > 0:
				features.append(node.feature)
				node = node.bnext
			else:
				node = node.next

		# try to match the kanji with the reading
		found = False
		for f in features:
			ff = f.split(",")
			if len(ff) < 7:
				return False

			kana = ff[6]

			# when the kana is the whole word, skip it
			if len(kana) == len(katakana):
				continue

			if katakanaleft.startswith(kana):
				found = True
				readings.append(kana)
				katakanaleft = katakanaleft[len(kana):]
				break

		# when one kanji fails we have to abort
		if not found:
			return False

	# check if all of the reading was "consumed"
	if len(katakanaleft) > 0:
		return False

	return True


def addfurigana_text(mecab, kakasi, text):
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

		# ignore any conversion other than kanji
		if not has_kanji(orig) or orig == hira:
			str += orig
			continue

		hasfurigana = True

		# find start and end
		a = 0
		b = 0

		for a in range(len(orig)):
			if orig[a] != hira[a]:
				break

		for b in range(len(orig)):
			n = len(orig) - b - 1
			m = len(hira) - b - 1
			if orig[n] != hira[m]:
				break

		borig = len(orig) - b
		bhira = len(hira) - b

		kanji = orig[a:borig]
		furigana = hira[a:bhira]
		prehiragana = hira[:a]
		posthiragana = hira[bhira:]

		# try if we can match each kanji to a specific reading
		matchedkana = False
		if len(kanji) > 1:
			readings = []
			matchedkana = find_reading(mecab, kakasi, kanji, furigana, readings)

		if matchedkana:
			s = prehiragana
			for k in range(len(kanji)):
				s += kanji[k] + openbracket + readings[k] + closebracket
			s += posthiragana
		else:
			s = prehiragana + kanji + openbracket + furigana + closebracket + posthiragana

		str += s

	return (hasfurigana, str)


def addfurigana(mecab, kakasi, entry, variant):
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

		if fixquotes:
			assert replacequotes not in v, "Use a different replacement"

			v = v.replace(escapedquote, replacequotes)

		xl = ET.fromstring(v)
		t = xl.attrib["t"]

		hasfurigana, str = addfurigana_text(mecab, kakasi, t)

		if hasfurigana:
			if fixquotes:
				str = str.replace(replacequotes, escapedquote)

			xl.attrib["t"] = str

			str2 = ET.tostring(xl, encoding="unicode")
			entry[variant] = str2
			return True

		return False

	else:
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
