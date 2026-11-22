extends Resource
class_name Event

enum CommandType {
	INVALID,
	BPMCHANGE,
	MEASURE,
	DELAY,
	SCROLL,
	SPEED,
	REVERSE,
	BRANCHSTART,
	BRANCHEND,
	GOGOSTART,
	GOGOEND,
	START,
	END,
}

@export var type: CommandType = CommandType.INVALID
@export var time: float = 0.0
@export var value1: float = 0.0
@export var value2: float = 0.0
@export var index: int = 0

func _init(_type: CommandType, _time: float = 0.0, _value1: float = 0.0, _value2: float = 0.0) -> void:
	type = _type
	time = _time
	value1 = _value1
	value2 = _value2
