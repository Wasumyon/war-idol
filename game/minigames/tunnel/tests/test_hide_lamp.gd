extends Node
var fails := 0
var checks := 0

func ok(c: bool, name: String) -> void:
	checks += 1
	if not c: fails += 1
	print(("PASS " if c else "FAIL ") + name)

func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame

func _ready() -> void:
	await get_tree().process_frame
	GameManager._busy = true
	var root = load("res://scenes/chambers/chamber_2.tscn").instantiate()
	add_child(root)
	await get_tree().process_frame
	var p = root.find_child("Player", true, false)
	GameManager._busy = false
	p.has_torch = true
	p.set_torch(false)
	await wait(0.05)
	var prompt: Label = p.get_node("ActionPrompt")
	ok(not prompt.visible, "lantern off does not show a cue")
	p.enter_hide_zone()
	await wait(0.05)
	ok(prompt.visible and prompt.text == "W", "hide cue takes priority at cover")
	p.set_hidden(true)
	await wait(0.05)
	ok(not prompt.visible, "hide cue disappears while hidden")
	p.exit_hide_zone()
	await wait(0.05)
	ok(not prompt.visible, "hide cue clears when leaving cover")
	GameManager._busy = true
	# lamp on -> hide -> off; unhide -> back on after the delay
	p.set_torch(true)
	p.set_hidden(true)
	ok(not p.is_torch_on, "hiding shields the lamp")
	await wait(0.3)
	ok(not p.is_torch_on, "stays off while hidden")
	p.set_hidden(false)
	ok(not p.is_torch_on, "not instant on step-out")
	await wait(0.3)
	ok(p.is_torch_on, "relights after stepping out")
	# lamp off -> hide -> unhide: stays off
	p.set_torch(false)
	p.set_hidden(true)
	p.set_hidden(false)
	await wait(0.3)
	ok(not p.is_torch_on, "stays off if it was off before hiding")
	# re-hide inside the delay: no relight while hidden
	p.set_torch(true)
	p.set_hidden(true)
	p.set_hidden(false)
	p.set_hidden(true)
	await wait(0.3)
	ok(not p.is_torch_on, "re-hiding during the relight delay keeps it off")
	p.set_hidden(false)
	await wait(0.3)
	ok(p.is_torch_on, "...and it comes back after the second step-out")
	GameManager._busy = false
	Input.action_press("action_torch")
	await wait(0.05)
	Input.action_release("action_torch")
	ok(not p.is_torch_on and not prompt.visible, "toggling the lantern does not show a cue")
	p.enter_hide_zone()
	await wait(0.05)
	ok(prompt.visible and prompt.text == "W", "hide cue appears with the lantern off")
	print("RESULT %d/%d" % [checks - fails, checks])
	get_tree().quit(1 if fails else 0)
