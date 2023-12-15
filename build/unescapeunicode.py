import os
import sys


def replace_timestamp(text):
	start = text.find('"ExportedDateTime":')
	if start >= 0:
		end = text.find(",", start)
		if end > start:
			ts = text[start:end]

			return text[:start] + '"ExportedDateTime": "2077-01-01T00:00:00.00Z"' + text[end:]

	return text


def unespace_text(text):
	pos = 0
	while True:
		pos = text.find("\\u", pos)
		if pos < 0:
			return text

		# check if this is a path
		if pos > 0 and text[pos-1] == "\\":
			pos += 1
			continue

		escaped = text[pos:pos + 6]

		if escaped == "\\u0022":
			uchar = "\\\""
		else:
			try:
				uchar = escaped.encode('latin1').decode('unicode-escape')
			except:
				print("Failed to unescape\"" + escaped + "\"")
				return None

		text = text[:pos] + uchar + text[pos + 6:]


def unescape_file(file):
	with open(file, 'r', encoding='utf8') as f:
		lines = f.readlines()

	for i in range(len(lines)):
		line = lines[i]

		unescaped = unespace_text(line)
		if unescaped is None:
			print("Failed to unescape file \"" + file + "\" line " + str(i) + ": \"" + line + "\"")
			continue

		unescaped = replace_timestamp(unescaped)

		lines[i] = unescaped

	with open(file, 'w', encoding='utf8') as f:
		f.writelines(lines)


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
