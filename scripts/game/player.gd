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
var _dirty_bl: bool = false
var _multimesh: MultiMesh

var _branch_tex: ImageTexture
var _branch_img: Image
var _branch_tex_bl: ImageTexture
var _branch_img_bl: Image
var _branch_dirty: bool = false
var _branch_dirty_bl: bool = false

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
	_build_branch_data_for_notes()

func _build_note_data():
	var notes: Array[Note] = selected_chart.drawable_notes
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
	var barlines: Array[Note] = selected_chart.drawable_barlines
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
		mm.set_instance_transform_2d(barline.draw_index, Transform2D())
		mm.set_instance_custom_data(barline.draw_index, Color(barline.hidden, 0, 0, 0))
	
	_data_tex_bl = ImageTexture.create_from_image(_data_img_bl)
	_mat_bl.set_shader_parameter("note_data", _data_tex_bl)
	_mat_bl.set_shader_parameter("atlas", _note_atlas)
	barline_renderer.multimesh = mm

func _build_branch_data_for_notes():
	var notes: Array[Note] = selected_chart.drawable_notes
	var count: int = notes.size()
	var rows: int = maxi(ceili(count / float(DATA_ROW)), 1)
	
	_branch_img = Image.create(DATA_ROW, rows, false, Image.FORMAT_RGBAF)
	
	for note in notes:
		_write_branch_data(note)
	
	_branch_tex = ImageTexture.create_from_image(_branch_img)
	_mat.set_shader_parameter("branch_data", _branch_tex)

func _build_branch_data_for_barlines():
	var notes: Array[Note] = selected_chart.drawable_barlines
	var count: int = notes.size()
	var rows: int = maxi(ceili(count / float(DATA_ROW)), 1)
	
	_branch_img_bl = Image.create(DATA_ROW, rows, false, Image.FORMAT_RGBAF)
	
	for note in notes:
		_write_branch_data(note)
	
	_branch_tex_bl = ImageTexture.create_from_image(_branch_img_bl)
	_mat_bl.set_shader_parameter("branch_data", _branch_tex_bl)

func _write_branch_data(note: Note):
	var x: int = (note.draw_index % DATA_ROW)
	var y: int = (note.draw_index) / DATA_ROW
	_branch_img.set_pixel(x, y, Color(note.section, note.branch, 0, 0))

func _write_note_data(note: Note):
	var x: int = (note.draw_index % DATA_ROW) * DATA_PART
	var y: int = (note.draw_index) / DATA_ROW
	var rect: Rect2 = NOTE_ATLAS_RECTS[Note.NoteType.DON]
	# TODO handle roll notes
	if NOTE_ATLAS_RECTS.has(note.type):
		rect = NOTE_ATLAS_RECTS[note.type]
	if note.type == Note.NoteType.ROLL_BODY and note.roll_head:
		rect = NOTE_ROLL_BODY_RECTS[note.roll_head.type]
	if note.type == Note.NoteType.END_ROLL and note.roll_head:
		rect = NOTE_ROLL_END_RECTS[note.roll_head.type]
	_data_img.set_pixel(x, y, Color(note.scroll.x, note.scroll.y, note.time, note.bpm))
	_data_img.set_pixel(x + 1, y, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	_data_img.set_pixel(x + 2, y, Color(note.type, 0, note.end_time, 0))
	_data_img.set_pixel(x + 3, y, Color(0, 0, 0, 0))
	if note.roll_tail:
		_data_img.set_pixel(x + 3, y, Color(note.roll_tail.scroll.x, note.roll_tail.scroll.y, note.roll_tail.time, note.roll_tail.bpm))
	if note.roll_head and note.roll_head.type == Note.NoteType.BALLOON:
		_data_img.set_pixel(x + 2, y, Color(note.type, note.roll_head.type, note.roll_head.end_time, 0))
		_data_img.set_pixel(x + 3, y, Color(note.roll_head.scroll.x, note.roll_head.scroll.y, note.roll_head.time, note.roll_head.bpm))
	if note.type == Note.NoteType.BALLOON:
		_data_img.set_pixel(x + 2, y, Color(note.type, 0, note.end_time, 0))

func _write_barline_data(note: Note):
	var x: int = (note.draw_index % DATA_ROW) * DATA_PART
	var y: int = (note.draw_index) / DATA_ROW
	var rect: Rect2 = NOTE_ATLAS_RECTS[Note.NoteType.BARLINE]
	if note.section_barline:
		rect.position.y += NOTE_SIZE.y
	_data_img_bl.set_pixel(x, y, Color(note.scroll.x, note.scroll.y, note.time, note.bpm))
	_data_img_bl.set_pixel(x + 1, y, Color(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	_data_img_bl.set_pixel(x + 2, y, Color(0, 0, 0, 0))
	_data_img_bl.set_pixel(x + 3, y, Color(0, 0, 0, 0))

func update_player(t: float) -> void:
	if _dirty:
		_data_tex.update(_data_img)
		_dirty = false
	if _dirty_bl:
		_data_tex_bl.update(_data_img_bl)
		_dirty_bl = false

	_mat.set_shader_parameter("t", t)
	_mat_bl.set_shader_parameter("t", t)

func update_player_physics(t: float) -> void:
	update_notes(t)
	_update_events(t)

var _autoplay_kat_side: int = 0
var _autoplay_don_side: int = 0
var _autoplay_drumroll: bool = false

var _branch_condition_count: float = 0
var _branch_note_count: int = 0
var _branch_drumroll_count: int = 0

func update_notes(t: float):
	if selected_chart.notes.size() == 0: return
	
	if _autoplay_drumroll:
		_autoplay_don_side = !_autoplay_don_side
		taiko.hit_side(TaikoDrum.Part.DON, _autoplay_don_side as TaikoDrum.Direction)
		_branch_drumroll_count += 1
	
	# Very much WIP LMAO
	while selected_chart.notes.back() and selected_chart.notes.back().time <= t:
		var note: Note = selected_chart.notes.pop_back()
		match note.type:
			Note.NoteType.DON, Note.NoteType.BIG_DON:
				_update_texture_hit_note(note)
				_autoplay_don_side = !_autoplay_don_side
				taiko.hit_side(TaikoDrum.Part.DON, _autoplay_don_side as TaikoDrum.Direction)
				_branch_condition_count += 1
				_branch_note_count += 1
			Note.NoteType.KAT, Note.NoteType.BIG_KAT:
				_update_texture_hit_note(note)
				_autoplay_kat_side = !_autoplay_kat_side
				taiko.hit_side(TaikoDrum.Part.KAT, _autoplay_kat_side as TaikoDrum.Direction)
				_branch_condition_count += 1
				_branch_note_count += 1
			Note.NoteType.ROLL, Note.NoteType.BIG_ROLL:
				_autoplay_drumroll = true
			Note.NoteType.END_ROLL:
				_autoplay_drumroll = false

var _current_branch_section: int = -1
var _current_selected_branch_path: Branch.BranchPath = Branch.BranchPath.NONE

func _update_events(t: float):
	if selected_chart.events.size() == 0: return
	
	while selected_chart.events.back() and selected_chart.events.back().time <= t:
		var event: Event = selected_chart.events.pop_back()
		match event.type:
			Event.CommandType.GOGOSTART:
				var tween: Tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(gogo_time_back, "modulate:a", 1.0, 0.13)
				tween.tween_property(gogo_time_lane, "scale:y", 1.0, 0.13)
			Event.CommandType.GOGOEND:
				var tween: Tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(gogo_time_back, "modulate:a", 0.0, 0.13)
				tween.tween_property(gogo_time_lane, "scale:y", 0.0, 0.13)
			Event.CommandType.BRANCHSTART:
				_evaluate_branch(event.value1)

func _evaluate_branch(branch_index: int):
	_current_branch_section += 1
	_current_selected_branch_path = Branch.BranchPath.NORMAL
	var branch: Branch = selected_chart.branches[branch_index]
	var notes_to_merge: Array[Note] = branch.normal_notes
	var events_to_merge: Array[Event] = branch.normal_events
	
	if branch.condition == Branch.BranchCondition.PERCENTAGE:
		_branch_condition_count = maxi(mini(floori(float(_branch_condition_count) / _branch_note_count * 100.0), 100), 0)
	elif branch.condition == Branch.BranchCondition.ROLL:
		_branch_condition_count = maxi(_branch_drumroll_count, floori(_branch_condition_count))
	
	if _branch_condition_count >= branch.expert_requirement and _branch_condition_count < branch.master_requirement and branch.expert_requirement > 0:
		notes_to_merge = branch.expert_notes
		events_to_merge = branch.expert_events
		_current_selected_branch_path = Branch.BranchPath.EXPERT
	elif _branch_condition_count >= branch.master_requirement:
		notes_to_merge = branch.master_notes
		events_to_merge = branch.master_events
		_current_selected_branch_path = Branch.BranchPath.MASTER
	
	for note in notes_to_merge:
		_update_instance_note(note)
	
	selected_chart.notes.append_array(notes_to_merge)
	selected_chart.notes.sort_custom(Chart.sort_note_func)
	selected_chart.events.append_array(events_to_merge)
	selected_chart.events.sort_custom(Chart.sort_event_func)
	
	print("Branched handled: section %d, switched to branch path %d" % [branch_index, _current_selected_branch_path])
	
	_branch_condition_count = 0
	# _branch_drumroll_count = 0
	_branch_note_count = 0

func _update_texture_hit_note(note: Note):
	note.hit = true
	_update_instance_note(note)
	#note.hit = true
	#_write_note_data(note)
	#_dirty = true

func _update_instance_note(note: Note):
	_multimesh.set_instance_custom_data(note.draw_index, Color(note.hit, _current_branch_section, _current_selected_branch_path, 0))

var _lane_hit_tween: Tween

@onready var _don_lane: TextureRect = $Main/Lane/DonLane
@onready var _kat_lane: TextureRect = $Main/Lane/KatLane
@onready var _good_lane: TextureRect = $Main/Lane/GoodLane

func _on_taiko_side_hit(part: TaikoDrum.Part, _side: TaikoDrum.Direction) -> void:
	if _lane_hit_tween:
		_lane_hit_tween.kill()
	(_don_lane if part == TaikoDrum.Part.DON else _kat_lane).modulate.a = 1.0
	(_kat_lane if part == TaikoDrum.Part.DON else _don_lane).modulate.a = 0
	_good_lane.modulate.a = 1.0
	_lane_hit_tween = create_tween()
	_lane_hit_tween.set_parallel(true)
	_lane_hit_tween.tween_property(_don_lane if part == TaikoDrum.Part.DON else _kat_lane, "modulate:a", 0, 0.067).set_delay(0.1)
	_lane_hit_tween.tween_property(_good_lane, "modulate:a", 0, 0.067).set_delay(0.1)
