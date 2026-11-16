extends RefCounted
## Dossier entries: loading, the two versions, links and glitch spans, validation.
## Spec: dossier_spec.md (repo root). Static helpers only; the screen is dossier.gd.
##
## State lives in Game.flags and nothing here saves:
##   file:<id>   the story has filed the entry
##   seen:<id>   the player has opened it   (new = filed and not seen)

const INLINE_MARKS := preload("res://inline_marks.gd")
const ENTRY_DIR := "res://dossier/entries/"
const SCENE_DIR := "res://scenes/"
const IMG_DIR := "res://img/"
const IMG_EXTS := ["png", "webp", "jpg", "jpeg"]
const REVEAL_FLAG := "visor_revealed"
const REVISED_FLAG := "dossier_revised"   ## the reveal has already cleared the seen:* flags
const ACCENT := "#79ead1"
const HEADER_KEYS := ["title", "category", "order", "image", "info", "source", "terms"]
## Proposed in the spec; story confirms. Order is the tab order.
const CATEGORIES := [
	{"id": "people", "name": "People"},
	{"id": "military", "name": "Cohort & Ministry"},
	{"id": "io", "name": "Io & the Colony"},
	{"id": "media", "name": "Media & Streams"},
	{"id": "guide", "name": "Field Guide"},
]

static var _entries := {}
static var _terms: Array = []      ## [[term, id], ...] longest term first
static var _loaded := false
static var _load_problems: Array[String] = []


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
static func reload() -> void:
	_entries = {}
	_terms = []
	_load_problems = []
	_loaded = true
	var dir := DirAccess.open(ENTRY_DIR)
	if dir == null:
		_load_problems.append("cannot open " + ENTRY_DIR)
		return
	var files := Array(dir.get_files())
	files.sort()
	for file in files:
		var name := str(file)
		if name.begins_with("_") or not name.ends_with(".txt"):
			continue
		var f := FileAccess.open(ENTRY_DIR + name, FileAccess.READ)
		if f == null:
			_load_problems.append("cannot read " + name)
			continue
		var id := name.get_basename()
		var entry := parse_entry(id, f.get_as_text())
		for p in entry.problems:
			_load_problems.append("%s: %s" % [id, p])
		_entries[id] = entry
	for id in _entries:
		for term in _entries[id].terms:
			_terms.append([term, id])
	_terms.sort_custom(func(a: Array, b: Array) -> bool: return str(a[0]).length() > str(b[0]).length())


## id -> entry. Entry keys: id title category order image info[[label, value]] source[] terms[]
## versioned before after problems[]
static func all() -> Dictionary:
	if not _loaded:
		reload()
	return _entries


static func entry(id: String) -> Dictionary:
	return all().get(id, {})


static func parse_entry(id: String, text: String) -> Dictionary:
	var e := {"id": id, "title": "", "category": "", "order": 0, "image": "", "info": [],
		"source": [], "terms": [], "versioned": false, "before": "", "after": "", "problems": []}
	var problems: Array = e.problems
	var lines := text.replace("\r\n", "\n").split("\n")
	var i := 0
	while i < lines.size() and lines[i].strip_edges() != "" and not lines[i].strip_edges().begins_with("=="):
		var line := lines[i].strip_edges()
		i += 1
		var colon := line.find(":")
		if colon <= 0:
			problems.append("bad header line '%s'" % line)
			continue
		var key := line.substr(0, colon).strip_edges()
		var value := line.substr(colon + 1).strip_edges()
		if not HEADER_KEYS.has(key):
			problems.append("unknown header '%s'" % key)
			continue
		match key:
			"order":
				if not value.is_valid_int():
					problems.append("order is not a number")
				e.order = int(value)
			"info":
				var bar := value.find("|")
				if bar < 0:
					problems.append("info line needs 'label | value'")
				else:
					e.info.append([value.substr(0, bar).strip_edges(), value.substr(bar + 1).strip_edges()])
			"source", "terms":
				for part in value.split(","):
					if part.strip_edges() != "":
						e[key].append(part.strip_edges())
			_:
				e[key] = value
	var plain: Array[String] = []
	var sections := {}
	var section := ""
	while i < lines.size():
		var raw := lines[i]
		i += 1
		var t := raw.strip_edges()
		if t == "== before" or t == "== after":
			section = t.substr(3)
			sections[section] = []
			continue
		if section == "":
			plain.append(raw)
		else:
			sections[section].append(raw)
	if sections.is_empty():
		e.before = "\n".join(plain).strip_edges()
		e.after = e.before
	else:
		e.versioned = true
		if "\n".join(plain).strip_edges() != "":
			problems.append("text before the first == section")
		e.before = "\n".join(sections.get("before", [])).strip_edges()
		e.after = "\n".join(sections.get("after", [])).strip_edges()
		if not sections.has("before") or not sections.has("after"):
			problems.append("'== before' and '== after' must come as a pair")
	if e.title == "":
		problems.append("missing title")
	if e.category == "":
		problems.append("missing category")
	return e


static func categories() -> Array:
	return CATEGORIES


static func category_name(id: String) -> String:
	for c in CATEGORIES:
		if c.id == id:
			return c.name
	return id


## Ids of the entries in a category ("" = all), sorted by order then id.
static func ids_in(category := "") -> Array[String]:
	var out: Array[String] = []
	for id in all():
		if category == "" or all()[id].category == category:
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		var oa: int = all()[a].order
		var ob: int = all()[b].order
		return oa < ob if oa != ob else a < b)
	return out


static func is_filed(id: String) -> bool:
	return all().has(id) and Game.has_flag("file:" + id)


static func is_new(id: String) -> bool:
	return is_filed(id) and not Game.has_flag("seen:" + id)


static func new_count() -> int:
	sync_reveal()
	var n := 0
	for id in all():
		if is_new(id):
			n += 1
	return n


static func revealed() -> bool:
	return Game.has_flag(REVEAL_FLAG)


## The reveal flips versioned entries to `after`; they come back as new (spec §3).
## Done once, by flag, in memory only. Call before listing or counting.
static func sync_reveal() -> void:
	if not revealed() or Game.has_flag(REVISED_FLAG):
		return
	for id in all():
		if all()[id].versioned:
			Game.set_flag("seen:" + id, false)
	Game.set_flag(REVISED_FLAG)


static func body_text(id: String, original := false) -> String:
	var e := entry(id)
	if e.is_empty():
		return ""
	return e.before if (original or not revealed()) else e.after


## An entry body as BBCode: "## " headings, paragraphs (wrapped source lines are joined).
static func render_body(id: String, original := false) -> String:
	var blocks: Array[String] = []
	var para: Array[String] = []
	for raw in body_text(id, original).split("\n"):
		var line := str(raw).strip_edges()
		if line.begins_with("## "):
			_flush(blocks, para, id)
			blocks.append("[color=%s]■ [b]%s[/b][/color]" % [ACCENT, mark_up(line.substr(3), id)])
		elif line == "":
			_flush(blocks, para, id)
		else:
			para.append(line)
	_flush(blocks, para, id)
	return "\n\n".join(blocks)


static func _flush(blocks: Array[String], para: Array[String], id: String) -> void:
	if not para.is_empty():
		blocks.append(mark_up(" ".join(para), id))
		para.clear()


# ---------------------------------------------------------------------------
# Marks: links, glitches, story terms, then the VN's inline marks
# ---------------------------------------------------------------------------
## Used for entry bodies and for VN lines. Glitch spans and [[links]] are pulled out first
## (parked in private-use characters), then story terms are linked, then the inline marks
## run, then everything is put back - so ids like nemean_cohort can't trip the mark passes.
## `self_id` is an entry whose own terms are left plain in its own body.
static func mark_up(text: String, self_id := "", link_terms := true) -> String:
	var held: Array[String] = []
	var t := _hold(text, "\\{\\{(.+?)\\}\\}", held, _glitch_span)
	t = _hold(t, "\\[\\[(.+?)\\]\\]", held, _hand_link)
	if link_terms:
		t = _link_terms(t, held, self_id)
	t = INLINE_MARKS.apply(t)
	for idx in range(held.size() - 1, -1, -1):
		t = t.replace(char(0xE000 + idx), held[idx])
	return t


static func _hold(text: String, pattern: String, held: Array[String], build: Callable) -> String:
	var re := RegEx.create_from_string(pattern)
	var found := re.search_all(text)
	for k in range(found.size() - 1, -1, -1):
		var m: RegExMatch = found[k]
		held.append(str(build.call(m.get_string(1))))
		text = text.substr(0, m.get_start()) + char(0xE000 + held.size() - 1) + text.substr(m.get_end())
	return text


static func _glitch_span(inner: String) -> String:
	var shown := inner
	var flag := ""
	var bar := inner.rfind("|")
	if bar >= 0 and not inner.substr(bar + 1).contains(" "):
		shown = inner.substr(0, bar)
		flag = inner.substr(bar + 1).strip_edges()
	if flag != "" and Game.has_flag(flag):
		return shown
	return "[glitch]%s[/glitch]" % shown


static func _hand_link(inner: String) -> String:
	var bar := inner.find("|")
	var id := (inner.substr(0, bar) if bar >= 0 else inner).strip_edges()
	var shown := inner.substr(bar + 1).strip_edges() if bar >= 0 else str(entry(id).get("title", id))
	return _link(id, shown)


## A link to a filed entry; plain highlighted text otherwise (no spoilers either way).
static func _link(id: String, shown: String) -> String:
	if is_filed(id):
		return "[url=%s][color=%s][u]%s[/u][/color][/url]" % [id, ACCENT, shown]
	return "[color=%s]%s[/color]" % [ACCENT, shown]


static func _is_word(c: String) -> bool:
	return c == "_" or c.to_upper() != c.to_lower() or c.is_valid_int()


## Whole-word, case-sensitive, longest form first. Skips BBCode tags. "\Term" stays plain.
static func _link_terms(t: String, held: Array[String], self_id: String) -> String:
	if _terms.is_empty() and not _loaded:
		reload()
	var out := ""
	var i := 0
	var n := t.length()
	while i < n:
		var ch := t[i]
		if ch == "[":
			var close := t.find("]", i)
			if close > i and not t.substr(i, close - i).contains(" "):
				out += t.substr(i, close - i + 1)
				i = close + 1
				continue
		var escaped := ch == "\\" and i + 1 < n
		var j := i + 1 if escaped else i
		var hit: Array = []
		if j == 0 or not _is_word(t[j - 1]) or escaped:
			hit = _term_at(t, j)
		if hit.is_empty():
			out += ch
			i += 1
			continue
		var term: String = hit[0]
		var id: String = hit[1]
		if escaped or id == self_id or not is_filed(id):
			out += term
		else:
			held.append(_link(id, term))
			out += char(0xE000 + held.size() - 1)
		i = j + term.length()
	return out


static func _term_at(t: String, j: int) -> Array:
	for pair in _terms:
		var term: String = pair[0]
		var end := j + term.length()
		if t.substr(j, term.length()) == term and (end >= t.length() or not _is_word(t[end])):
			return pair
	return []


## True when `text` uses `term` as a word and not escaped with a backslash (validation).
static func uses_term(text: String, term: String) -> bool:
	var from := 0
	while true:
		var at := text.find(term, from)
		if at < 0:
			return false
		var end := at + term.length()
		var before_ok := at == 0 or not _is_word(text[at - 1])
		var escaped := at > 0 and text[at - 1] == "\\"
		if (before_ok or escaped) and not escaped and (end >= text.length() or not _is_word(text[end])):
			return true
		from = at + 1
	return false


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
static func image_exists(name: String) -> bool:
	if name.begins_with("res://"):
		return ResourceLoader.exists(name)
	for ext in IMG_EXTS:
		if ResourceLoader.exists("%s%s.%s" % [IMG_DIR, name, ext]):
			return true
	return false


## Problems that should fail a build. Debug builds push these from MainGame.
static func validate() -> Array[String]:
	var out: Array[String] = []
	out.append_array(_load_problems_now())
	var cats := {}
	for c in CATEGORIES:
		cats[c.id] = true
	var orders := {}
	var term_owner := {}
	var link_re := RegEx.create_from_string("\\[\\[([^\\]|]+)")
	for id in all():
		var e: Dictionary = all()[id]
		if e.category != "" and not cats.has(e.category):
			out.append("%s: unknown category '%s'" % [id, e.category])
		var key := "%s/%d" % [e.category, e.order]
		if orders.has(key):
			out.append("%s: order %d in '%s' is also used by %s" % [id, e.order, e.category, orders[key]])
		orders[key] = id
		if e.image != "" and not image_exists(e.image):
			out.append("%s: missing image '%s'" % [id, e.image])
		for term in e.terms:
			if term_owner.has(term):
				out.append("%s: term '%s' is also listed by %s" % [id, term, term_owner[term]])
			term_owner[term] = id
		for m in link_re.search_all(e.before + "\n" + e.after):
			var target := m.get_string(1).strip_edges()
			if not all().has(target):
				out.append("%s: [[%s]] points at no entry" % [id, target])
	for hit in _scene_files_scan():
		if hit.kind == "file" and not all().has(hit.id):
			out.append("%s: '@ file %s' names no entry" % [hit.path, hit.id])
	return out


static func _load_problems_now() -> Array[String]:
	all()
	return _load_problems.duplicate()


## Not failures: a term used in a scene before (or without) the `@ file` that files it.
static func warnings() -> Array[String]:
	var out: Array[String] = []
	var filed_somewhere := {}
	var hits := _scene_files_scan()
	for hit in hits:
		if hit.kind == "file":
			filed_somewhere[hit.id] = true
	var filed_in_file := {}   # path -> {id: true} so far
	for hit in hits:
		var done: Dictionary = filed_in_file.get(hit.path, {})
		filed_in_file[hit.path] = done
		if hit.kind == "file":
			done[hit.id] = true
			continue
		for id in all():
			if done.has(id) or (filed_somewhere.has(id) and not _filed_later_in(hits, hit, id)):
				continue
			for term in all()[id].terms:
				if uses_term(hit.text, term):
					out.append("%s: '%s' appears before '@ file %s'" % [hit.path, term, id])
					break
	return out


static func _filed_later_in(hits: Array, at: Dictionary, id: String) -> bool:
	var seen_at := false
	for h in hits:
		if h == at:
			seen_at = true
		elif seen_at and h.path == at.path and h.kind == "file" and h.id == id:
			return true
	return false


## Every `@ file <id>` and every prose line of the scenes, in file order.
static func _scene_files_scan() -> Array:
	var out: Array = []
	for path in _scene_paths(SCENE_DIR):
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		for raw in f.get_as_text().split("\n"):
			var line := str(raw).strip_edges()
			if line == "" or line.begins_with("#") or line.begins_with("==") or line.begins_with("?") \
					or line.begins_with("+") or line.begins_with("->"):
				continue
			if line.begins_with("@"):
				var parts := line.substr(1).strip_edges().split(" ", true, 1)
				if str(parts[0]) == "file" and parts.size() > 1:
					out.append({"kind": "file", "path": path.trim_prefix("res://"), "id": str(parts[1]).strip_edges()})
			else:
				out.append({"kind": "line", "path": path.trim_prefix("res://"), "text": line})
	return out


static func _scene_paths(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	var names := Array(dir.get_files())
	names.sort()
	for name in names:
		if str(name).ends_with(".txt") and not str(name).begins_with("_"):
			out.append(dir_path.path_join(name))
	var subs := Array(dir.get_directories())
	subs.sort()
	for sub in subs:
		out.append_array(_scene_paths(dir_path.path_join(sub)))
	return out


## `source:` paths are relative to the repo root, one level above the Godot project.
## Meant for the test, which runs from the repo.
static func validate_sources(repo_root: String) -> Array[String]:
	var out: Array[String] = []
	for id in all():
		for src in all()[id].source:
			if not FileAccess.file_exists(repo_root.path_join(src)):
				out.append("%s: source '%s' does not exist" % [id, src])
		if all()[id].source.is_empty():
			out.append("%s: no source: line" % id)
	return out
