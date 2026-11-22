extends TextureRect
class_name TaikoDrum

enum Direction {
	LEFT = 0,
	RIGHT = 1
}

enum Part {
	DON = 0,
	KAT = 1
}

@onready var kat: Array[TextureRect] = [$KatLeft, $KatRight]
@onready var don: Array[TextureRect] = [$DonLeft, $DonRight]
@onready var kat_sounds: Array[AudioStreamPlayer] = [$KatLeftSound, $KatRightSound]
@onready var don_sounds: Array[AudioStreamPlayer] = [$DonLeftSound, $DonRightSound]
var kat_tweens: Array[Tween] = [null, null]
var don_tweens: Array[Tween] = [null, null]

func hit_side(part: Part, side: Direction):
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
			tween.tween_property(don[side], "modulate:a", 0.0, 0.1).set_delay(0.1)
			don_tweens[side] = tween
		Part.KAT:
			kat[side].modulate.a = 1.0
			tween.tween_property(kat[side], "modulate:a", 0.0, 0.1).set_delay(0.1)
			kat_tweens[side] = tween
