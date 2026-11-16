extends Node
## Run with --headless --path vn res://tests/dossier_test.tscn.  Spec: dossier_spec.md §7, §11.
## Touches Game.flags in memory only; nothing here saves.

const DATA := preload("res://dossier/dossier_data.gd")
const DOSSIER_SCENE := preload("res://dossier/dossier.tscn")
const VN_SCENE := preload("res://vn.tscn")
const SCENE_FILE := "user://dossier_test_scene.txt"

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> bool:
	if not ok:
		_failures += 1
		push_error(what)
	return ok


func _run() -> void:
	Game.flags = {}
	DATA.reload()

	# --- data ---------------------------------------------------------------
	var problems := DATA.validate()
	_check(problems.is_empty(), "validate: %s" % str(problems))
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var bad_sources := DATA.validate_sources(repo)
	_check(bad_sources.is_empty(), "sources: %s" % str(bad_sources))
	_check(DATA.all().size() >= 3, "sample entries load")
	for w in DATA.warnings():
		print("warning: ", w)

	# --- the screen: new, seen, reveal --------------------------------------
	var d: CanvasLayer = DOSSIER_SCENE.instantiate()
	add_child(d)
	var a := "placeholder_person"
	var b := "placeholder_unit"
	_check(d.list_ids("new").is_empty(), "nothing filed: New is empty")
	Game.set_flag("file:" + a)
	_check(d.list_ids("new") == [a], "a filed entry is listed in New")
	_check(d.list_ids("people") == [a] and d.list_ids("military").is_empty(), "tabs list their own category")
	_check(DATA.new_count() == 1, "new count is 1")
	d.open(a)
	_check(d.is_open() and get_tree().paused, "open() shows the files and pauses the tree")
	_check(Game.has_flag("seen:" + a), "opening an entry sets seen:<id>")
	_check(d.list_ids("new").is_empty() and DATA.new_count() == 0, "a read entry is no longer new")
	_check(d.body_bbcode().contains("[glitch]xxxxxxxx[/glitch]"), "before-reveal text shows the glitched span")
	_check(not d.body_bbcode().contains("[url=" + b), "a link to an unfiled entry is not clickable")
	_check(d.body_bbcode().contains("Placeholder Unit") or d.body_bbcode().contains("a unit"), "hand link text is shown")
	d.close()
	_check(not get_tree().paused, "close() unpauses a tree it paused")

	Game.set_flag("file:" + b)
	d.open(a)
	_check(d.body_bbcode().contains("[url=" + b + "]"), "a link to a filed entry is clickable")
	d.close()

	Game.set_flag(d.REVEAL_FLAG)
	_check(d.list_ids("new") == [a, b] or d.list_ids("new") == [a], "the reveal makes revised files new again")
	_check(d.list_ids("new").has(a), "entry a is new again after the reveal")
	d.open(a)
	_check(d.body_bbcode().contains("(revised)"), "after the reveal the entry shows its after text")
	d._original.button_pressed = true
	_check(not d.body_bbcode().contains("(revised)"), "Original filing shows the before text")
	d.close()

	# --- glitch spans -------------------------------------------------------
	_check(DATA.mark_up("{{x|f}}").contains("[glitch]x[/glitch]"), "a glitch span renders glitched")
	Game.set_flag("f")
	_check(DATA.mark_up("{{x|f}}") == "x", "a glitch span clears once its flag is set")
	_check(DATA.mark_up("{{x}}").contains("[glitch]"), "a flagless glitch span never clears")

	# --- story terms (§11) --------------------------------------------------
	_check(not DATA.mark_up("The Placeholder Place is quiet.").contains("[url="), "an unfiled term stays plain")
	Game.set_flag("file:placeholder_place")
	var linked := DATA.mark_up("The Placeholder Place is quiet.")
	_check(linked.contains("[url=placeholder_place]") and linked.contains("[u]Placeholder Place[/u]"), "a filed term is underlined and linked")
	_check(not DATA.mark_up("The \\Placeholder Place is quiet.").contains("[url="), "backslash-Term stays plain")
	_check(DATA.mark_up("The \\Placeholder Place is quiet.").contains("The Placeholder Place"), "backslash-Term loses its backslash")
	_check(not DATA.mark_up("Placeholder Placed and Placeholder Places").contains("[url="), "terms match whole words only")
	_check(not DATA.mark_up("{{Placeholder Place}}").contains("[url="), "glitched text is never linked")
	_check(DATA.mark_up("*Placeholder Place*").contains("[i]"), "inline marks still run around a link")
	var own := DATA.render_body("placeholder_unit", true)
	_check(own.contains("[url=" + a + "]"), "a term inside an entry body links to a filed entry")

	# --- the VN: @ file, link, click ----------------------------------------
	var f := FileAccess.open(SCENE_FILE, FileAccess.WRITE)
	f.store_string("@ file placeholder_feed\nChip: Placeholder Feed and the Placeholder Place.\nChip: Second line.\nChip: Third line.\n")
	f.close()
	var vn: Control = VN_SCENE.instantiate()
	vn.begin({"file": SCENE_FILE})
	var filed_ids: Array[String] = []
	vn.filed.connect(func(id: String) -> void: filed_ids.append(id))
	var clicked: Array[String] = []
	vn.term_clicked.connect(func(id: String) -> void: clicked.append(id))
	vn.term_clicked.connect(d.open)
	add_child(vn)
	_check(filed_ids == ["placeholder_feed"] and Game.has_flag("file:placeholder_feed"), "@ file sets the flag and emits filed")
	var shown: String = vn._compose_text({"text": "Placeholder Feed here.", "staging": [], "modes": {}})
	_check(shown.contains("[url=placeholder_feed]"), "the first mention after @ file is already underlined")
	vn._on_term_clicked("placeholder_unit")
	_check(clicked == ["placeholder_unit"] and d.is_open() and d.current == "placeholder_unit", "clicking a link opens that entry")
	d.close()

	# a click that hit a link must not advance the line; any other click still does
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	vn._link_hover = 1
	var before_state: bool = vn._revealing
	vn._unhandled_input(click)
	_check(vn._revealing == before_state and before_state, "a click on a link does not advance the line")
	vn._link_hover = 0
	click.position = vn.text_label.get_global_rect().get_center()
	get_viewport().push_input(click)
	_check(not vn._revealing, "a click on plain text (through the label) still advances the line")

	vn.queue_free()
	d.queue_free()
	DirAccess.remove_absolute(SCENE_FILE)
	Game.flags = {}
	get_tree().paused = false
	print("Dossier test: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
