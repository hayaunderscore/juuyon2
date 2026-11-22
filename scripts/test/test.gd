extends Node2D

@onready var butan: Button = $Control/Button
@onready var dialog: FileDialog = $FileDialog

@onready var difficulty_container: VBoxContainer = $Control/MarginContainer/DifficultyContainer
@onready var song_title: Label = $Control/MarginContainer2/SongInfo/SongTitle
@onready var song_subtitle: Label = $Control/MarginContainer2/SongInfo/SongSubtitle
@onready var sample_song: AudioStreamPlayer = $AudioStreamPlayer

var game_scene: PackedScene = load("uid://cah68c1djyc52")

var loaded_song: Song = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.tja ; TJA files"])

func _on_button_pressed() -> void:
	dialog.popup_centered()

func _on_difficulty_button_pressed(index: int):
	var scene: GameScene1P = game_scene.instantiate()
	scene.song = loaded_song
	scene.selected_chart_index = index
	TJAParser.parse_tja_note_data(loaded_song, index)
	sample_song.stop()
	get_tree().change_scene_to_node(scene)

func _on_file_dialog_file_selected(path: String) -> void:
	loaded_song = TJAParser.parse_tja_metadata(path)
	song_title.text = loaded_song.title
	song_subtitle.text = loaded_song.subtitle.lstrip("--")
	sample_song.stream = TJAParser.get_song_wave(loaded_song)
	sample_song.play(loaded_song.demo_start)
	
	for child in difficulty_container.get_children():
		child.queue_free()
	
	var idx: int = 0
	for chart in loaded_song.charts:
		var button: Button = Button.new()
		button.text = "%s ★%d" % [Chart.CourseType.find_key(chart.course_type), chart.level]
		button.pressed.connect(func():
			_on_difficulty_button_pressed(idx)
		)
		difficulty_container.add_child(button)
		idx += 1
	#for note in song.charts[1].notes:
		#print(note)
