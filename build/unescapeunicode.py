import sys, os


def unescape_file(file):
	with open(file, 'r', encoding='utf8') as f:
		content = f.read()

	if "\\u" in content:
		escaped = content.encode('latin1').decode('unicode-escape')

		escaped = escaped.replace("\\", "\\\\")

		with open(file, 'w', encoding='utf8') as f:
			f.write(escaped)


def unescape_folder(path):
	for f in os.listdir(path):
		p = os.path.join(path, f)

		if os.path.isdir(p):
			unescape_folder(p)
		else:
			unescape_file(p)


if __name__ == '__main__':
	if len(sys.argv) < 2:
		print("No path given.")
		exit(1)

	p = sys.argv[1]

	if not os.path.isdir(p):
		print("No such path \"" + p + "\".")
		exit(1)

	unescape_folder(p)

	exit(0)
