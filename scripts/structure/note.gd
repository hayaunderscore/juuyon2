extends Resource
class_name Note

enum NoteType {
	NONE,
	DON,
	KAT,
	BIG_DON,
	BIG_KAT,
	ROLL,
	BIG_ROLL,
	BALLOON,
	END_ROLL,
	KUSADAMA,
	# OpenTaiko-Outfox standard
	SWAP,	# G
	BOMB,	# C
	FUSE,	# D
	ADLIB,	# F
	# Special "notes" (starts at 999)
	BARLINE = 999, # Yes. A barline is a notetype.
	GOGOSTART,
	GOGOEND,
	EMPTY,
	ROLL_HEAD, # Generally, roll heads are considered as a note only for the draw list.
}

const NOTE_ROLL_HEADS: Dictionary[NoteType, bool] = {
	NoteType.ROLL: true,
	NoteType.BIG_ROLL: true,
	NoteType.BALLOON: true,
	NoteType.KUSADAMA: true,
	NoteType.FUSE: true,
}

const NOTE_CHAR_TO_TYPE: Dictionary[String, NoteType] = {
	"0": NoteType.EMPTY,
	"1": NoteType.DON,
	"2": NoteType.KAT,
	"3": NoteType.BIG_DON,
	"4": NoteType.BIG_KAT,
	"5": NoteType.ROLL,
	"6": NoteType.BIG_ROLL,
	"7": NoteType.BALLOON,
	"8": NoteType.END_ROLL,
	"9": NoteType.KUSADAMA,
	"G": NoteType.SWAP,
	"C": NoteType.BOMB,
	"D": NoteType.FUSE,
	"F": NoteType.ADLIB
}

@export var type: NoteType = NoteType.NONE
@export var time: float = 0.0
@export var bpm: float = 0.0
@export var meter: float = 0.0
@export var scroll: Vector2 = Vector2.ZERO
@export var hidden: bool = false

@export var roll_head: Note = null
@export var balloon_value: int = 0
@export var gogotime: bool = false
@export var index: int = 0
@export var draw_index: int = 0
@export var phonetic: int = 0

var hit: bool = false

func _init(_type: NoteType, _time: float, _scroll: Vector2, _idx: int, _hidden: bool = false):
	type = _type
	time = _time
	scroll = _scroll
	index = _idx
	hidden = _hidden

func _to_string() -> String:
	return "TYPE: %s ; TIME: %f ; SCROLL: (%f, %f)" % [NoteType.find_key(type), time, scroll.x, scroll.y]
