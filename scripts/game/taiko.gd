extends TextureRect
class_name TaikoDrum

var combo_texture: Texture2D = load("uid://q71pluu8iq87")
var combo_100_texture: Texture2D = load("uid://dh4338p0vaa2a")

enum Direction {
	LEFT = 0,
	RIGHT = 1
}

enum Part {
	DON = 0,
	KAT = 1
}

signal side_hit(part: Part, side: Direction)

@onready var kat: Array[TextureRect] = [$KatLeft, $KatRight]
@onready var don: Array[TextureRect] = [$DonLeft, $DonRight]
@onready var kat_sounds: Array[AudioStreamPlayer] = [$KatLeftSound, $KatRightSound]
@onready var don_sounds: Array[AudioStreamPlayer] = [$DonLeftSound, $DonRightSound]
@onready var combo_text: StretchableNumber = $Combo

var kat_tweens: Array[Tween] = [null, null]
var don_tweens: Array[Tween] = [null, null]

var combo: int = 0:
	set(value):
		combo = value
		if is_instance_valid(combo_text):
			_update_combo_texture()
			combo_text.visible = combo >= 10
			combo_text.value = combo

func _update_combo_texture():
	if combo < 100:
		combo_text.texture = combo_texture
		combo_text.cell_size = Vector2.ONE * combo_texture.get_size().y
		combo_text.offset = Vector2(-16, 0)
		combo_text.pivot.y = combo_text.cell_size.y
		combo_text.position.y = 52
	else:
		combo_text.texture = combo_100_texture
		combo_text.cell_size = Vector2.ONE * combo_100_texture.get_size().y
		combo_text.offset = Vector2(-18, 0)
		combo_text.pivot.y = combo_text.cell_size.y
		combo_text.position.y = 48

func hit_side(part: Part, side: Direction):
	side_hit.emit(part, side)
	match part:
		Part.DON:
			don_sounds[side].play()
			if don_tweens[side] and don_tweens[side].is_valid():
				don_tweens[side].kill()
		Part.KAT:
			kat_sounds[side].play()
			if kat_tweens[side] and kat_tweens[side].is_valid():
				kat_tweens[side].kill()
	var tween: Tween = create_tween()
	match part:
		Part.DON:
			don[side].modulate.a = 1.0
			tween.tween_property(don[side], "modulate:a", 0.0, 0.067).set_delay(0.1)
			don_tweens[side] = tween
		Part.KAT:
			kat[side].modulate.a = 1.0
			tween.tween_property(kat[side], "modulate:a", 0.0, 0.067).set_delay(0.1)
			kat_tweens[side] = tween
