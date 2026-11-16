extends RefCounted
## Reads calendar_data.gd against the saved GameState state. Holds no state of its own.

const DATA := preload("res://calendar/calendar_data.gd")


## What plays next: {"kind": "segment" | "hub" | "end", "id": String}.
static func next_step() -> Dictionary:
	if GameState.day > DATA.LAST_DAY:
		return {"kind": "end", "id": ""}
	if DATA.SEGMENTS.has(GameState.active_segment):
		return {"kind": "segment", "id": GameState.active_segment}
	var fixed := scripted_pending()
	if fixed != "" and DATA.DAYS[GameState.day].get("skip_hub", false):
		return {"kind": "segment", "id": fixed}
	return {"kind": "hub", "id": ""}


static func segment(id: String) -> Dictionary:
	return DATA.SEGMENTS.get(id, {})


## The scripted list for the current slot; empty on a free slot.
static func scripted_list() -> Array:
	var slots: Dictionary = DATA.DAYS.get(GameState.day, {}).get("slots", {})
	return slots.get(DATA.SLOT_KEYS[GameState.slot], [])


## The next unplayed scripted segment in the current slot, or "".
static func scripted_pending() -> String:
	for id in scripted_list():
		if not GameState.segment_done(id):
			return id
	return ""


## What the hub's Missions list shows for the current slot.
static func offers() -> Array[String]:
	var fixed := scripted_pending()
	if fixed != "":
		return [fixed]
	var out: Array[String] = []
	for id in DATA.OFFERS:
		var seg: Dictionary = DATA.SEGMENTS[id]
		if seg.get("once", false) and GameState.segment_done(id):
			continue
		if int(seg.get("slots", 1)) > GameState.SLOTS_PER_DAY - GameState.slot:
			continue
		if allowed(seg.get("requires", {})):
			out.append(id)
	return out


static func allowed(requires: Dictionary) -> bool:
	for flag in requires.get("flags_all", []):
		if not GameState.has_flag(flag):
			return false
	for flag in requires.get("flags_none", []):
		if GameState.has_flag(flag):
			return false
	return GameState.day >= int(requires.get("min_day", 1)) \
		and GameState.day <= int(requires.get("max_day", DATA.LAST_DAY))


## Slots this segment uses up when it finishes: 0 while its scripted list has more to play.
static func slots_used(id: String) -> int:
	var list := scripted_list()
	if id in list and id != list[-1]:
		return 0
	return int(segment(id).get("slots", 1))


static func outputs_for(id: String, result: Dictionary) -> Dictionary:
	var seg := segment(id)
	var out: Dictionary = seg.get("outputs", {}).duplicate(true)
	var extra: Dictionary = seg.get("outcomes", {}).get(str(result.get("outcome", "")), {})
	for key in extra:
		if out.has(key) and out[key] is Dictionary:
			out[key].merge(extra[key], true)
		else:
			out[key] = extra[key]
	return out


static func is_checkpoint(day: int) -> bool:
	return day % DATA.CHECKPOINT_EVERY == 0


static func slot_name() -> String:
	return DATA.SLOT_NAMES[GameState.slot]


## Debug builds only: every problem found in the data, as text.
static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	for id in DATA.SEGMENTS:
		var seg: Dictionary = DATA.SEGMENTS[id]
		var type := str(seg.get("type", ""))
		if type not in ["vn", "minigame", "skip"]:
			problems.append("%s: unknown type '%s'" % [id, type])
		var source := str(seg.get("source", ""))
		if type == "minigame" and not ResourceLoader.exists(source):
			problems.append("%s: no scene at '%s'" % [id, source])
		if type == "vn" and source != "" and not FileAccess.file_exists(source):
			problems.append("%s: no script at '%s'" % [id, source])
	var seen := {}
	for day in DATA.DAYS:
		var slots: Dictionary = DATA.DAYS[day].get("slots", {})
		for key in slots:
			if key not in DATA.SLOT_KEYS:
				problems.append("day %d: unknown slot '%s'" % [day, key])
			for id in slots[key]:
				if not DATA.SEGMENTS.has(id):
					problems.append("day %d: unknown segment '%s'" % [day, id])
				if seen.has(id):
					problems.append("day %d: '%s' is scripted twice" % [day, id])
				seen[id] = true
	for id in DATA.OFFERS:
		if not DATA.SEGMENTS.has(id):
			problems.append("offers: unknown segment '%s'" % id)
		elif seen.has(id):
			problems.append("offers: '%s' is also scripted" % id)
	return problems
