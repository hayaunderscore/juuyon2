@tool
extends Control
class_name StretchableNumber

class Digit:
	var receding: bool
	var time: float
	var digit: int

var _digits: Array[Digit]
var _force_redraw: bool = false

func _get_nth_digit(num: int, digit: int) -> int:
	return str(num)[digit].to_int()

func _recreate_digits():
	_digits.resize((1 if value == 0 else floori(log(value) / log(10)) + 1))
	for i in _digits.size():
		if _digits[i] == null: _digits[i] = Digit.new()
		var digit: Digit = _digits[i]
		digit.digit = _get_nth_digit(value, (_digits.size() - 1) - i)
		if stretch_time > 0:
			digit.time = stretch_time
			digit.receding = false
		digit.time = stretch_recede

@export var value: int = 0:
	set(val):
		value = maxi(0, val) # This cannot go below zero.
		_recreate_digits()

@export_group("Visuals")
@export var texture: Texture2D:
	set(val):
		if texture == val: return
		texture = val
		_force_redraw = true
@export var cell_size: Vector2:
	set(val):
		if cell_size == val: return
		cell_size = val
		_force_redraw = true
@export var offset: Vector2:
	set(val):
		if offset == val: return
		offset = val
		_force_redraw = true
@export var pivot: Vector2
@export var align: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT:
	set(val):
		if align == val: return
		align = val
		_force_redraw = true

@export_group("Animation")
@export var stretch: Vector2
@export var stretch_time: float
@export var stretch_recede: float = 0.1
@export var stretch_individual: bool = false
@export var stretch_minimum_digits: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_digits.resize((1 if value == 0 else floori(log(value) / log(10)) + 1))
	_recreate_digits()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var redraw: bool = false
	for digit in _digits:
		redraw = true
		digit.time -= delta
		if digit.time < 0:
			if stretch_time > 0 and not digit.receding:
				digit.receding = true
				digit.time = stretch_recede
				continue
			redraw = false
			digit.time = 0
	if redraw or _force_redraw:
		_force_redraw = false
		queue_redraw()

func _draw() -> void:
	if texture == null: return
	var x: float = 0
	var y: float = 0
	var length: int = _digits.size()
	match align:
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER:
			x -= length * (cell_size.x + offset.x) / 2
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT:
			x -= length * (cell_size.x + offset.x)
	for i in range(length - 1, -1, -1):
		var digit: Digit = _digits[i]
		var t: float = digit.time
		if stretch_time > 0 and not digit.receding:
			t = stretch_time - digit.time
		draw_set_transform(Vector2(x, y) + pivot, 0, Vector2.ONE + (stretch * t))
		draw_texture_rect_region(
			texture, 
			Rect2(-pivot.x, -pivot.y, cell_size.x, cell_size.y),
			Rect2(digit.digit * cell_size.x, 0, cell_size.x, cell_size.y))
		x += cell_size.x + offset.x
		y += offset.y
