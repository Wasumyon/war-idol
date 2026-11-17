extends "res://tests/tunnel_test.gd"
## The demo shell with the tunnel entry: title -> controls -> tunnel (intro, ending
## sequence) -> result -> play again -> result. No save is written along the way.

const SHELL := preload("res://demo/demo_shell.tscn")
const REAL_SAVE := "user://campaign.save"

var shell: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().create_timer(60.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timed out")
		get_tree().quit(2))
	# Any GameState write would land here; the real save's timestamp must not move either.
	var temp_save := OS.get_temp_dir().path_join("war-idol-demo-%d.save" % OS.get_process_id())
	GameState._save_path = temp_save
	var real_existed := FileAccess.file_exists(REAL_SAVE)
	var real_mtime := FileAccess.get_modified_time(REAL_SAVE) if real_existed else 0

	shell = SHELL.instantiate()
	shell.demo = "tunnel"
	add_child(shell)
	await frames(2)
	ok(shell.screen == &"title", "the shell opens on the title screen")
	ok(shell.stamp != "", "the title screen has a build stamp")
	ok(shell.entry.title == "Tunnel Escape", "the tunnel entry is loaded")

	shell.to_controls()
	ok(await shell.shown == &"controls", "Start leads to the controls screen")

	await _play_once("first run")
	ok(shell.result.get("deaths") == 0, "the result carries the death count")

	await _play_once("play again")
	ok(get_tree().root.find_child("Debug", true, false) == null, "no debug panel in the tree")

	shell.to_title()
	ok(await shell.shown == &"title", "Title screen leads back to the title")

	ok(not FileAccess.file_exists(temp_save), "GameState wrote no save")
	ok(FileAccess.file_exists(REAL_SAVE) == real_existed
		and (not real_existed or FileAccess.get_modified_time(REAL_SAVE) == real_mtime),
		"user://campaign.save is untouched")
	DirAccess.remove_absolute(temp_save)
	finish()


func _play_once(label: String) -> void:
	shell.play()
	ok(await shell.shown == &"segment", label + ": the tunnel segment is shown")
	seg = shell.segment
	m = TunnelManager.i
	ok(m != null and m.get_parent().get_parent().get_parent() == seg, label + ": its manager is live")
	ok(seg.start == "intro" and seg.ending == "sequence", label + ": begin got intro + sequence")
	ok(m.chamber_path.ends_with("intro.tscn"), label + ": the run opens on the intro")
	await wait(0.5)
	m.finish()
	ok(await shell.shown == &"result", label + ": finishing shows the result screen")
	ok(shell.result.get("outcome") == "escaped", label + ": outcome is escaped")
	ok(shell.segment == null and TunnelManager.i == null, label + ": the segment is gone")
