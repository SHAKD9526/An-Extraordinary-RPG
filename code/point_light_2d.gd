extends PointLight2D
var cd: float = 0.2
var timer: float = 0.0

func _process(delta):
	timer -= delta
	# 灯光朝向鼠标
	var mouse_world = get_global_mouse_position()
	var dir = mouse_world - global_position
	global_rotation = dir.angle()
	
	# 在这里判断按键，不会报错
	if Input.is_action_just_pressed("toggle_light") and timer <= 0:
		visible = !visible
		timer = cd
