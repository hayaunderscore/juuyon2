extends Control
class_name Player

@export var song: Song
@export var selected_chart: Chart

@onready var barline_renderer: MultiMeshInstance2D = $Main/Lane/JudgePoint/Barlines
@onready var note_renderer: MultiMeshInstance2D = $Main/Lane/JudgePoint/Notes
@onready var taiko: TaikoDrum = $Main/TaikoBackground/Taiko

@onready var gogo_time_lane: TextureRect = $Main/Lane/GogoTimeLane
@onready var gogo_time_back: TextureRect = $GogoTimeBack

var _note_atlas: Texture2D = preload("res://graphics/game/notes.png")
var _data_tex: ImageTexture
var _data_img: Image
var _data_tex_bl: ImageTexture
var _data_img_bl: Image
var _dirty: bool = false
var _multimesh: MultiMesh

const DATA_ROW: int = 256
const DATA_PART: int = 4

const NOTE_SIZE: Vector2 = Vector2(96, 96)
const NOTE_ATLAS_RECTS: Dictionary[Note.NoteType, Rect2] = {
	Note.NoteType.DON: Rect2(1 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.KAT: Rect2(2 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BIG_DON: Rect2(3 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BIG_KAT: Rect2(4 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.ROLL: Rect2(5 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BIG_ROLL: Rect2(8 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BALLOON: Rect2(11 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.END_ROLL: Rect2(7 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.KUSADAMA: Rect2(11 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BARLINE: Rect2(0 * NOTE_SIZE.x, 1 * NOTE_SIZE.y, NOTE_SIZE.x, NOTE_SIZE.y),
}
const NOTE_ROLL_END_RECTS: Dictionary[Note.NoteType, Rect2] = {
	Note.NoteType.ROLL: Rect2(7 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BIG_ROLL: Rect2(10 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BALLOON: Rect2(12 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.KUSADAMA: Rect2(12 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
}
const NOTE_ROLL_BODY_RECTS: Dictionary[Note.NoteType, Rect2] = {
	Note.NoteType.ROLL: Rect2(6 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
	Note.NoteType.BIG_ROLL: Rect2(9 * NOTE_SIZE.x, 0, NOTE_SIZE.x, NOTE_SIZE.y),
}

@onready var _mat: ShaderMaterial = note_renderer.material
@onready var _mat_bl: ShaderMaterial = barline_renderer.material

func build() -> void:
	_build_note_data()
	_build_barline_data()

func _build_note_data():
	var notes: Array[Note] = selected_chart.notes
	var count: int = notes.size()
	var rows: int = maxi(ceili(count / float(DATA_ROW)), 1)
	
	_data_img = Image.create(DATA_ROW * DATA_PART, rows, false, Image.FORMAT_RGBAF)
	
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = quad
	mm.use_custom_data = true
	mm.instance_count = count
	mm.custom_aabb = AABB(Vector3(-100000, -100000, -1), Vector3(200000, 200000, 2))
	
	for note in notes:
		_write_note_data(note)
		mm.set_instance_transform_2d(note.draw_index, Transform2D())
		mm.set_instance_custom_data(note.draw_index, Color())
	
	_data_tex = ImageTexture.create_from_image(_data_img)
	_mat.set_shader_parameter("note_data", _data_tex)
	_mat.set_shader_parameter("atlas", _note_atlas)
	_multimesh = mm
	note_renderer.multimesh = mm

func _build_barline_data():
	var barlines: Array[Note] = selected_chart.barlines
	var count: int = barlines.size()
	var rows: int = maxi(ceili(count / float(DATA_ROW)), 1)
	
	_data_img_bl = Image.create(DATA_ROW * DATA_PART, rows, false, Image.FORMAT_RGBAF)
	
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = quad
	mm.use_custom_data = true
	mm.instance_count = count
	mm.custom_aabb = AABB(Vector3(-100000, -100000, -1), Vector3(200000, 200000, 2))
	
	for barline in barlines:
		_write_barline_data(barline)
		mm.set_instance_transform_2d(barline.index, Transform2D())
		mm.set_instance_custom_data(barline.index, Color(barline.hidden, 0, 0, 0))
	
	_data_tex_bl = ImageTexture.create_from_image(_data_img_bl)
	_mat_bl.set_shader_parameter("note_data", _data_tex_bl)
	_mat_bl.set_shader_parameter("atlas", _note_atlas)
	barline_renderer.multimesh = mm

func _write_note_data(note: Note):
	var x: int = (note.draw_index % DATA_ROW) * DATA_PART
	var y: int = (note.draw_index) / DATA_ROW
	var rect: Rect2 = NOTE_ATLAS_RECTS[Note.NoteType.DON]
	# TODO handle roll notes
	if NOTE_ATLAS_RECTS.has(note.type):
		rect = NOTE_ATLAS_RECTS[note.type]
	_data_img.set_pixel(x, y, Color(note.scroll.x, note.scroll.y, note.time, note.bpm))
	_data_img.set_pixel(x + 1, y, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	_data_img.set_pixel(x + 2, y, Color(0, 0, 0, 0))
	_data_img.set_pixel(x + 3, y, Color(0, 0, 0, 0))

func _write_barline_data(note: Note):
	var x: int = (note.index % DATA_ROW) * DATA_PART
	var y: int = (note.index) / DATA_ROW
	var rect: Rect2 = NOTE_ATLAS_RECTS[Note.NoteType.BARLINE]
	_data_img_bl.set_pixel(x, y, Color(note.scroll.x, note.scroll.y, note.time, note.bpm))
	_data_img_bl.set_pixel(x + 1, y, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	_data_img_bl.set_pixel(x + 2, y, Color(0, 0, 0, 0))
	_data_img_bl.set_pixel(x + 3, y, Color(0, 0, 0, 0))

func update_player(t: float) -> void:
	if _dirty:
		_data_tex.update(_data_img)
		_dirty = false

	_mat.set_shader_parameter("t", t)
	_mat_bl.set_shader_parameter("t", t)

func update_player_physics(t: float) -> void:
	update_notes(t)
	_update_events(t)

var _autoplay_kat_side: int = 0
var _autoplay_don_side: int = 0

func update_notes(t: float):
	if selected_chart.notes.size() == 0: return
	
	# Very much WIP LMAO
	while selected_chart.notes.back() and selected_chart.notes.back().time <= t:
		var note: Note = selected_chart.notes.pop_back()
		match note.type:
			Note.NoteType.DON, Note.NoteType.BIG_DON:
				_update_texture_hit_note(note)
				_autoplay_don_side = !_autoplay_don_side
				taiko.hit_side(TaikoDrum.Part.DON, _autoplay_don_side as TaikoDrum.Direction)
			Note.NoteType.KAT, Note.NoteType.BIG_KAT:
				_update_texture_hit_note(note)
				_autoplay_kat_side = !_autoplay_kat_side
				taiko.hit_side(TaikoDrum.Part.KAT, _autoplay_kat_side as TaikoDrum.Direction)

func _update_events(t: float):
	if selected_chart.events.size() == 0: return
	
	while selected_chart.events.back() and selected_chart.events.back().time <= t:
		var event: Event = selected_chart.events.pop_back()
		match event.type:
			Event.CommandType.GOGOSTART:
				var tween: Tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(gogo_time_back, "modulate:a", 1.0, 0.15)
				tween.tween_property(gogo_time_lane, "scale:y", 1.0, 0.1)
			Event.CommandType.GOGOEND:
				var tween: Tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(gogo_time_back, "modulate:a", 0.0, 0.15)
				tween.tween_property(gogo_time_lane, "scale:y", 0.0, 0.1)

func _update_texture_hit_note(note: Note):
	_multimesh.set_instance_custom_data(note.draw_index, Color(1, 0, 0, 0))
	#note.hit = true
	#_write_note_data(note)
	#_dirty = true
