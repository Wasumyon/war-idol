extends Node
## Music survives chamber changes and respawns; the final room has its own loop.

const APEX: String = "res://minigames/tunnel/art/music/Apex_Prey_Loop.ogg"
const LEAP: String = "res://minigames/tunnel/art/music/Leap_of_Faith_Loop.ogg"
const FINAL_ROOM: String = "res://minigames/tunnel/scenes/chambers/chamber_5.tscn"
const VOLUME_DB: float = -14.0
const CROSSFADE_TIME: float = 2.0
const MUSIC_BUS: StringName = &"Soundtrack"

var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _track: String = ""
var _transition: Tween
var _muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
	for i: int in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.volume_db = -80.0
		add_child(player)
		player.bus = MUSIC_BUS
		_players.append(player)
	GameManager.chamber_changed.connect(_select_music)
	# Autoloads enter before the main scene, including when running a room directly.
	await get_tree().process_frame
	if get_tree().current_scene:
		_select_music(get_tree().current_scene.scene_file_path)


func _select_music(scene_path: String) -> void:
	if not scene_path.begins_with("res://minigames/tunnel/scenes/chambers/chamber_"):
		return
	var path: String = LEAP if scene_path == FINAL_ROOM else APEX
	if path == _track:
		return
	_track = path
	if _transition:
		_transition.kill()
	var previous: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var current: AudioStreamPlayer = _players[_active]
	current.stop()
	var stream: AudioStreamOggVorbis = load(path) as AudioStreamOggVorbis
	stream.loop = true
	current.stream = stream
	current.volume_db = -80.0
	current.play()
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(previous, "volume_db", -80.0, CROSSFADE_TIME)
	_transition.tween_property(current, "volume_db", VOLUME_DB, CROSSFADE_TIME)
	_transition.chain().tween_callback(previous.stop)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_M:
		_muted = not _muted
		# Keep playback advancing while muted, including during a crossfade.
		AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), _muted)
		get_viewport().set_input_as_handled()
