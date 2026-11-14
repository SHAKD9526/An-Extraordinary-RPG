extends Node2D
var cd: float = 1.0
var timer: float = 0.0
var turn_speed = 10.0
var target_angle = 0.0
@export var light: PointLight2D

func _process(delta):
	timer -= delta
	var mouse_world = get_global_mouse_position()
	var dir = mouse_world - global_position
	target_angle = dir.angle()
	global_rotation = move_toward_angle(global_rotation, target_angle, turn_speed * delta)

	# 直接在process里用Input全局判断，避开event的坑
	if Input.is_action_just_pressed("toggle_light") and timer <= 0:
		light.visible = !light.visible
		SoundManager.play_light()
		timer = cd

func move_toward_angle(from: float, to: float, step: float) -> float:
	var diff = to - from
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
		
	if diff > step:
		return from + step
	elif diff < -step:
		return from - step
	return to
