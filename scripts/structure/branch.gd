extends Resource
class_name Branch

enum BranchCondition {
	NONE,
	PERCENTAGE,
	ROLL,
	SCORE
}

enum BranchPath {
	NONE,
	NORMAL,
	EXPERT,
	MASTER
}

const STR_TO_COND: Dictionary[String, BranchCondition] = {
	"p": BranchCondition.PERCENTAGE,
	"r": BranchCondition.ROLL,
	"s": BranchCondition.SCORE,
}

@export var condition: BranchCondition = BranchCondition.PERCENTAGE
@export var expert_requirement: int = 0
@export var master_requirement: int = 0
@export var time: float = 0.0
@export var index: int = 0

@export var normal_notes: Array[Note]
@export var normal_barlines: Array[Note]
@export var normal_events: Array[Event]
@export var normal_delays: Array[Event]

@export var expert_notes: Array[Note]
@export var expert_barlines: Array[Note]
@export var expert_events: Array[Event]
@export var expert_delays: Array[Event]

@export var master_notes: Array[Note]
@export var master_barlines: Array[Note]
@export var master_events: Array[Event]
@export var master_delays: Array[Event]

func sort_everything():
	normal_notes.sort_custom(Chart.sort_note_func)
	normal_events.sort_custom(Chart.sort_event_func)
	expert_notes.sort_custom(Chart.sort_note_func)
	expert_events.sort_custom(Chart.sort_event_func)
	master_notes.sort_custom(Chart.sort_note_func)
	master_events.sort_custom(Chart.sort_event_func)
