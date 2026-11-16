extends RefCounted
## The calendar as data. Spec: maingame_spec.md (repo root).
##
## SEGMENTS  id -> one playable thing.
##   type      "vn", "minigame", or "skip" (passes the slot, plays nothing)
##   source    vn: a scenes/*.txt path; "" walks Game.chapters (the Day 1 opening).
##             minigame: a scene whose root emits finished(result).
##   title     what the hub's Missions list shows
##   blurb     one line under the title
##   args      passed to the segment's begin()
##   slots     slots it uses when it ends its slot (default 1; 2 = the whole day)
##   requires  {flags_all, flags_none, min_day, max_day}
##   once      an offer that disappears after it is played
##   outputs   {flags, stats, followers, money} applied on completion
##   outcomes  result.outcome -> a further outputs dictionary
##
## DAYS  day -> {skip_hub, slots: {"day": [ids], "evening": [ids]}}.
##   A slot with a list is scripted and plays the list in order.
##   A slot with no list, and any day with no entry, is free: the player picks from OFFERS.
##
## Everything from Day 2 on is PLACEHOLDER content that proves the loop.

const LAST_DAY := 40
const CHECKPOINT_EVERY := 5
const SLOT_NAMES := ["Day", "Evening"]
const SLOT_KEYS := ["day", "evening"]

const SEGMENTS := {
	"d01_opener": {
		"type": "minigame",
		"source": "res://opener/opener.tscn",
		"title": "Contact",
	},
	"d01_opening": {
		"type": "vn",
		"source": "",
		"title": "First stream",
		"slots": 2,
	},
	"d02_keno_evening": {
		"type": "vn",
		"source": "res://scenes/placeholder/d02_keno_evening.txt",
		"title": "Keno's, after hours",
		"blurb": "Story. Chip wants to talk about the numbers.",
		"outputs": {"flags": {"met_keno_evening": true}},
	},
	"d03_frontline": {
		"type": "minigame",
		"source": "res://runner/runner_segment.tscn",
		"title": "Frontline: the perimeter road",
		"blurb": "Story. Chip has a route and will not hear no.",
		"args": {"route": "medium", "zone": "perimeter"},
		"outcomes": {
			"good": {"followers": 200, "money": 150, "flags": {"perimeter_filmed": true}},
			"bad": {"followers": 20, "money": 40},
		},
	},
	"offer_runner_easy": {
		"type": "minigame",
		"source": "res://runner/runner_segment.tscn",
		"title": "Film the supply road",
		"blurb": "Frontline, easy route.",
		"args": {"route": "easy", "zone": "supply_road"},
		"outcomes": {
			"good": {"followers": 60, "money": 70},
			"bad": {"followers": 5, "money": 20},
		},
	},
	"offer_runner_hard": {
		"type": "minigame",
		"source": "res://runner/runner_segment.tscn",
		"title": "Film the sulfur pits",
		"blurb": "Frontline, hard route. Opens once the perimeter is on tape.",
		"args": {"route": "hard", "zone": "sulfur_pits"},
		"requires": {"flags_all": ["perimeter_filmed"]},
		"outcomes": {
			"good": {"followers": 260, "money": 220},
			"bad": {"followers": 10, "money": 0},
		},
	},
	"offer_canteen": {
		"type": "vn",
		"source": "res://scenes/placeholder/offer_canteen.txt",
		"title": "Canteen with Chip",
		"blurb": "A short scene.",
		"once": true,
	},
	"offer_rest": {
		"type": "skip",
		"title": "Rest",
		"blurb": "Let the slot go by.",
	},
}

const DAYS := {
	1: {"skip_hub": true, "slots": {"day": ["d01_opener", "d01_opening"]}},
	2: {"slots": {"evening": ["d02_keno_evening"]}},
	3: {"slots": {"day": ["d03_frontline"]}},
}

const OFFERS := ["offer_runner_easy", "offer_runner_hard", "offer_canteen", "offer_rest"]
