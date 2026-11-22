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

@export var raw_data: String
