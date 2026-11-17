extends RefCounted
## The browser demos (docs/demo_spec.md): one entry per minigame. The shell plays the entry
## whose name matches the export preset's custom feature `demo_<name>` (preset `demo_tunnel`
## sets the feature `demo_tunnel` and plays "tunnel").
##
## Adding a demo: one entry here, one `demo_<name>` preset in game/export_presets.cfg (copy
## demo_tunnel and change its feature and include list), then `tools/export_demo.ps1 <name>`.
##
## Entry fields:
##   title     shown big on the title screen
##   blurb     one or two lines under the title
##   controls  [[keys, what they do], ...] for the controls screen
##   segment   path of the segment's root scene (loaded at run time, so the shell's own
##             dependencies never pull another demo's files into a pack)
##   args      passed to the segment's begin(args)
##   outcomes  {result.outcome: headline on the result screen}
##   results   [[result key, label], ...] other result values to show, in order

const ENTRIES := {
	"tunnel": {
		"title": "Tunnel Escape",
		"blurb": "A short stealth escape through the old bunker tunnels.",
		"controls": [
			["A / D", "Move"],
			["Shift", "Sprint"],
			["Space", "Toggle lantern"],
			["W", "Hide in cover"],
			["E", "Interact"],
			["R", "Restart checkpoint"],
			["Esc", "Pause / resume"],
		],
		"segment": "res://minigames/tunnel/tunnel_segment.tscn",
		"args": {"start": "intro", "ending": "sequence"},
		"outcomes": {"escaped": "You escaped."},
		"results": [["deaths", "Deaths"]],
	},
	# "runner": {...}   next, per docs/demo_spec.md build order
	# "stealth": {...}
}
