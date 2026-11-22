extends Resource
class_name Branch

enum BranchCondition {
	PERCENTAGE,
	ROLL,
	SCORE
}

@export var condition: BranchCondition = BranchCondition.PERCENTAGE
@export var expert_requirement: int = 0
@export var master_requirement: int = 0
@export var time: float = 0.0
@export var index: int = 0

@export var notes: Array[Note]
@export var barlines: Array[Note]
@export var events: Array[Event]
@export var bpm_events: Array[Event]
@export var delays: Array[Event]
