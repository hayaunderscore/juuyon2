extends Resource
class_name Chart

enum CourseType {
	EASY,
	NORMAL,
	HARD,
	ONI,
	EDIT,
	URA = 4,
	TOWER,
	DAN,
}

enum ChartFlags {
	NONE = 0,
	BMSCROLL = (1 << 0),
	HBSCROLL = (1 << 1),
}

@export var course_type: CourseType = CourseType.ONI
@export var level: int = 0
@export var balloons: PackedInt32Array
@export var balloon_nor: PackedInt32Array
@export var balloon_exp: PackedInt32Array
@export var balloon_mas: PackedInt32Array
@export var score_init: int = 300
@export var score_diff: int = 1000
@export var hidden_branch: bool = false
@export var flags: int = 0

@export var notes: Array[Note]
@export var barlines: Array[Note]
@export var events: Array[Event]
@export var bpm_events: Array[Event]
@export var delays: Array[Event]
@export var branches: Array[Branch]

var drawable_notes: Array[Note]
var drawable_barlines: Array[Note]

@export var raw_data: String

static func sort_note_func(a: Note, b: Note):
	if a.time == b.time:
		return a.index > b.index
	return a.time > b.time

static func sort_event_func(a: Event, b: Event):
	if a.time == b.time:
		return a.index > b.index
	return a.time > b.time

static func sort_branch_func(a: Branch, b: Branch):
	if a.time == b.time:
		return a.index > b.index
	return a.time > b.time

static func sort_every_fucking_note_ever_func(a: Note, b: Note):
	if a.time == b.time:
		if a.index == b.index:
			if a.section == b.section:
				return a.branch > b.branch
			return a.section > b.section
		return a.index > b.index
	return a.time > b.time

func sort_everything():
	notes.sort_custom(sort_note_func)
	events.sort_custom(sort_event_func)
	# branches.sort_custom(sort_branch_func)
	for branch in branches:
		branch.sort_everything()

func add_drawables():
	drawable_notes.append_array(notes)
	drawable_barlines.append_array(barlines)
	for branch in branches:
		drawable_notes.append_array(branch.normal_notes)
		drawable_notes.append_array(branch.expert_notes)
		drawable_notes.append_array(branch.master_notes)
		drawable_barlines.append_array(branch.normal_barlines)
		drawable_barlines.append_array(branch.expert_barlines)
		drawable_barlines.append_array(branch.master_barlines)
	# Are you getting tired of sorting yet?
	drawable_notes.sort_custom(sort_every_fucking_note_ever_func)
	for i in drawable_notes.size():
		drawable_notes[i].draw_index = i
	for i in drawable_barlines.size():
		drawable_barlines[i].draw_index = i
