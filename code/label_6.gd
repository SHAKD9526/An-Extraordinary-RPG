extends Label
@export var swing_strength: float = 0.2
@export var sway_speed: float = 1.75

var time: float = 0.0
var original_rot: float = 0.0

func _ready():
	original_rot = rotation
	pivot_offset = Vector2(0.0, size.y / 2.0)

func _process(delta):
	time += delta
	var noise_rot = simplex_noise_2d(time * sway_speed, 88.0)
	rotation = original_rot + noise_rot * swing_strength

func simplex_noise_2d(x: float, y: float) -> float:
	return sin(x) * 0.6 + sin(x*2.1 + y) * 0.35 + sin(x*0.7 + y*1.3) * 0.25
