extends Control
class_name GameScene1P

var song: Song
var selected_chart_index: int

@onready var audio: AudioStreamPlayer = $Audio
@onready var song_title: Label = $SongTitleBar/MarginContainer/SongTitle

var _latency: float = AudioServer.get_output_latency()
var _last: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio.stream = TJAParser.get_song_wave(song)
	audio.stop()
	song_title.text = song.title_localized.get("ja", song.title)
	
	$Player.song = song
	$Player.selected_chart = song.charts[selected_chart_index]
	$Player.build()
	
	game_elapsed = -2
	
	_last = Time.get_ticks_usec()

var game_elapsed: float = 0.0
var _audio_started: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var now: float = Time.get_ticks_usec()
	var dt: float = (now - _last) / 1000000.0
	_last = now
	game_elapsed += dt * audio.pitch_scale
	
	var audio_elapsed: float = 0.0
	if audio.playing and _audio_started:
		audio_elapsed = audio.get_playback_position()
		if !audio.stream_paused: audio_elapsed += AudioServer.get_time_since_last_mix()
		audio_elapsed -= _latency
	
		var diff: float = audio_elapsed - game_elapsed
		if abs(diff) > 0.05:
			game_elapsed = audio_elapsed
		else:
			game_elapsed += diff * 0.1
	else:
		if game_elapsed > 0.0 and audio.stream != null and not _audio_started:
			audio.play(game_elapsed)
			_audio_started = true
	
	$Player.update_player(game_elapsed)
	$Label.text = "%f" % [game_elapsed]
	$Label2.text = "%d FPS" % [Engine.get_frames_per_second()]

func _physics_process(delta: float) -> void:
	$Player.update_player_physics(game_elapsed)
	
