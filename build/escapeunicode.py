import sys, os

def unespace_nonunicode(text):
	pos = 0
	while True:
		pos = text.find("\\x", pos)
		if pos < 0:
			return text

		escaped = text[pos:pos+4]

		uchar = escaped.encode('latin1').decode('unicode-escape')

		text = text[:pos] + uchar + text[pos+4:]


def escape_file(file):
	if not file.endswith(".json.json"):
		return

	with open(file, 'r', encoding='utf8') as f:
		content = f.read()

	escaped = content.encode('unicode-escape').decode('utf8').replace("\\n", "\n")

	escaped = unespace_nonunicode(escaped)

	with open(file, 'w', encoding='utf8') as f:
		f.write(escaped)


def escape_folder(path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			escape_folder(p)
		else:
			escape_file(p)


if __name__ == '__main__':
	if len(sys.argv) < 2:
		print("No path given.")
		exit(1)

	p = sys.argv[1]

	if not os.path.isdir(p):
		print("No such path \"" + p + "\".")
		exit(1)

	escape_folder(p)

	exit(0)
