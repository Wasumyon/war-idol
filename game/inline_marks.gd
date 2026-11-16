extends RefCounted
## The VN's inline shorthand (docs/style_guide.md §10), shared by vn.gd and the dossier.


## Inline shorthand, Markdown/CommonMark order. Triples and doubles run BEFORE the
## singles, or ***bold italic*** is read as a bold pair plus two loose asterisks, and
## __bold__ comes out as garbage. \* \_ \` \^ \, make a LITERAL mark: they are parked in
## control characters for the duration of the passes and restored at the end, which is
## what keeps a stray mark from mangling a line.
## Needs a matching pair; a lone mark is left alone.
static func apply(s: String) -> String:
	var t := s
	var park := {"\\*": "\u0001", "\\_": "\u0002", "\\`": "\u0003", "\\^": "\u0004", "\\,": "\u0005"}
	for k in park:
		t = t.replace(k, park[k])
	t = _wrap(t, "***", "b", "i")   # ***bold italic***
	t = _wrap(t, "___", "b", "i")   # ___bold italic___
	t = _wrap(t, "**", "b")         # **bold**
	t = _wrap(t, "__", "b")         # __bold__
	t = _wrap(t, "*", "i")          # *italic*
	t = _wrap(t, "_", "i")          # _italic_
	t = _wrap(t, "`", "code")       # `code`
	t = _wrap(t, "^^", "sup")   # ^^x^^  superscript
	t = _wrap(t, "^", "sup")    # ^x^    superscript (single form also works)
	t = _wrap(t, ",,", "sub")   # ,,x,,  subscript  (~ collides with Chip's tildes)
	for k in park:
		t = t.replace(park[k], k.substr(1))
	return t


static func _wrap(s: String, mark: String, tag: String, tag2 := "") -> String:
	var parts := s.split(mark)
	if parts.size() < 3:
		return s
	var open := "[%s]" % tag
	var close := "[/%s]" % tag
	if tag2 != "":
		open += "[%s]" % tag2
		close = "[/%s]" % tag2 + close
	var out := ""
	for idx in parts.size():
		if idx % 2 == 1:
			out += open + parts[idx] + close
		else:
			out += parts[idx]
	return out
