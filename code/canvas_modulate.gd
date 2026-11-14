extends CanvasModulate

# 三个阶段颜色
@export var color_day: Color = Color(1,1,1)
@export var color_dusk: Color = Color(0.72,0.65,0.55)
@export var color_night: Color = Color(0.08,0.1,0.18)

@export var cycle_speed: float = 0.013
var time: float = 0.0

func _process(delta):
	#print("昼夜t值：", GameState.day_night_t)
	time += delta * cycle_speed
	var t = fmod(time, 3.0) # 0~白天，1~黄昏，2~夜晚，3循环
	
	if t < 1.0:
		color = color_day.lerp(color_dusk, t)
	elif t < 2.0:
		color = color_dusk.lerp(color_night, t - 1.0)
	else:
		color = color_night.lerp(color_day, t - 2.0)

	# 同步到全局GameState，单色读取这个
	GameState.day_night_t = t
