# requires mecab-python3, unidic and pykakasi package
import os, sys, json, unicodedata, MeCab, unidic, pykakasi
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


def find_reading(mecab, kakasi, additionalreadings, kanji, furigana, readings, problems, filename):
	# get katakana reading
	katakana = kakasi.convert(furigana)[0]["kana"]

	# get all the readings for the kanji
	katakanaleft = katakana

	for k in kanji:
		found = False

		# check if we have an additional reading for this
		if k in additionalreadings:
			foundreadings = additionalreadings[k]

		else:
			foundreadings = []
			node = mecab.parseToNode(k + "一")  # this is a hack to get the Chinese reading
			while node:
				if len(node.surface) > 0:
					sp = node.feature.split(",")
					if len(sp) >= 7:
						foundreadings.append(sp[6])
					node = node.bnext
				else:
					node = node.next

		# try to match the kanji with the reading
		for kana in foundreadings:
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
			problems.append( (filename, "Could not match kanji \"" + k + "\" to kana \"" + katakanaleft + "\".") )
			return False

	# check if all of the reading was "consumed"
	if len(katakanaleft) > 0:
		problems.append( (filename, "Matched all kanji of \"" + kanji + "\" to \"" + katakana + "\" but \"" + katakanaleft + "\" was left over.") )
		return False

	return True


def addfurigana_text(mecab, kakasi, additionalreadings, text, problems, filename):
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

		# handle the case of an untranslated kanji
		if len(hira) < 1:
			problems.append( (filename, "Failed to translate '" + orig + "'.") )
			continue

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
			matchedkana = find_reading(mecab, kakasi, additionalreadings, kanji, furigana, readings, problems, filename)

		if matchedkana:
			s = prehiragana
			for k in range(len(kanji)):
				s += kanji[k] + openbracket + readings[k] + closebracket
			s += posthiragana
		else:
			s = prehiragana + kanji + openbracket + furigana + closebracket + posthiragana

		str += s

	return (hasfurigana, str)


def addfurigana(mecab, kakasi, additionalreadings, entry, variant, problems, filename):
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

		hasfurigana, str = addfurigana_text(mecab, kakasi, additionalreadings, t, problems, filename)

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
		hasfurigana, str = addfurigana_text(mecab, kakasi, additionalreadings, v, problems, filename)

		if hasfurigana:
			entry[variant] = str
			return True

		return False


def processjson(mecab, kakasi, additionalreadings, file, jsn, problems):
	chunks = jsn["Chunks"]

	for c in chunks:
		cc = chunks[c]
		t = cc["Type"]

		if t == "localizationPersistenceSubtitleEntries" and "Properties" in cc:
			props = cc["Properties"]
			entries = props["entries"]

			hasfurigana = False
			for e in entries:
				if addfurigana(mecab, kakasi, additionalreadings, e, "femaleVariant", problems, file):
					hasfurigana = True
				if addfurigana(mecab, kakasi, additionalreadings, e, "maleVariant", problems, file):
					hasfurigana = True

			if hasfurigana:
				file = file.replace("\\", "/")
				outfile = file.replace("/Raw/", "/Raw_Subtitles/")
				outdir = os.path.dirname(outfile)

				if not os.path.isdir(outdir):
					os.makedirs(outdir)

				with open(outfile, "w", encoding="utf8") as f:
					json.dump(jsn, f, indent=2, ensure_ascii=False, check_circular=False)


def process(mecab, kakasi, additionalreadings, path, filen, count, problems):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			filen = process(mecab, kakasi, additionalreadings, p, filen, count, problems)

		elif f.endswith(".json"):
			p1 = 10 * filen // count
			filen += 1
			p2 = 10 * filen // count

			if p1 != p2:
				sys.stdout.write(" " + str(p2 * 10) + "%")

			with open(p, "r", encoding="utf8") as ff:
				jsn = json.load(ff)
				processjson(mecab, kakasi, additionalreadings, p, jsn, problems)

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

# taken from https://github.com/MikimotoH/furigana/blob/master/furigana/furigana.py
mecab = MeCab.Tagger()  #"-Ochasen"
kakasi = pykakasi.kakasi()

count = countfiles(sourcepath)
problems = []

# when no reading can be found, we try to use one of these readings instead
additionalreadings = {
	"世": ["セイ", "セ", "ソウ"],
	"当": ["トウ"],
	"応": ["オウ", "ヨウ", "ノウ"],
	"己": ["コ", "キ"],
	"売": ["バイ"],
	"楽": ["ガク", "ラク", "ゴウ"]
}

sys.stdout.write("Processing 0%")
process(mecab, kakasi, additionalreadings, sourcepath, 0, count, problems)
sys.stdout.write(" done.\n")

for p in problems:
	print( p[0] + ": " + p[1])
