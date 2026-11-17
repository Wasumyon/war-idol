extends "res://tests/tunnel_test.gd"
## Headless check for Chamber 5: walk in, controls drop, he sits by the
## furnace, banging in the vent, he stands with the lamp on, the grille falls,
## Chip drops out, then the CG with text lines (advanced), closing card, Enter ends the segment.
func _ready() -> void:
	run()

func run() -> void:
	await start_segment({"ending": "sequence"})
	await load_chamber("res://minigames/tunnel/scenes/chambers/chamber_5.tscn")
	var e = sc.find_child("Ending", true, false)
	var grille = sc.find_child("Grille", true, false)
	ok(p.controls_enabled, "controls on at the start")
	p.global_position.x = 640
	await wait(0.5)
	ok(not p.controls_enabled, "walking in drops the controls")
	await wait(5.0)
	ok(absf(p.global_position.x - e.sit_x) < 12.0 and not p.is_sitting, "walked to the furnace and stands by it")
	await wait(2.5)
	ok(p.facing == -1, "banging: he turns to the vent")
	await wait(1.0)
	ok(p.is_torch_on, "lamp on, facing the vent")
	await wait(2.2)
	ok(grille.position.y > 200.0, "grille burst off and fell")
	var chip = sc.find_child("Chip", true, false)
	ok(chip != null and absf(chip.global_position.y) < 30.0, "Chip dropped out and landed")
	ok(e.chip_pose == "dazed" or e.chip_pose == "rub", "landed on her bum")
	await wait(3.0)
	ok(e.chip_pose == "knees", "onto her knees")
	await wait(6.5)
	ok(e._cg.visible and e._cg.modulate.a > 0.9, "ending CG shown")
	ok(e._log.get_child_count() == 1 and e._log.get_child(0).modulate.a > 0.9, "first text line beside the CG")
	for i in e.cg_lines.size():
		if i == 2:
			ok(e._log.get_child_count() == 3 and e._log.get_child(0).modulate.a < 0.6, "lines stack, older ones dim")
		e.advance()
		await wait(1.5)
	await wait(0.8)
	ok(e._card.visible, "after the last line: closing card")
	await wait(3.5)
	# The ending's "play again" became "continue": Enter now hands the segment its result.
	ok(e._can_finish, "continue offered (was: play again)")
	var enter := InputEventAction.new()
	enter.action = "ui_accept"
	enter.pressed = true
	e._unhandled_input(enter)
	await frames(2)
	ok(results.size() == 1 and results[0].get("outcome") == "escaped", "Enter ends the segment with outcome escaped")
	finish()
