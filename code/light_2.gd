extends PointLight2D

@export var max_energy: float = 0.7
@export var transition_speed: float = 1.0
@export var start_light_t: float = 0.6
@export var full_light_t: float = 1.3
@export var t_offset: float = 0.0
@export var flicker_strength: float = 0.08   # 篝火默认幅度比灯笼大
@export var flicker_speed: float = 7.0

# 天亮熄灭区间
@export var start_dim_t: float = 2.5
@export var fully_off_t: float = 3.0

var target_energy: float = 0.0
var flicker_rng: RandomNumberGenerator
var flicker_time: float = 0.0
@onready var game_state = get_node("/root/GameState")

func _ready():
	flicker_rng = RandomNumberGenerator.new()
	flicker_rng.randomize()

func _process(delta):
	var t = game_state.day_night_t + t_offset
	t = fmod(t, 3.0)
	var base_energy = 0.0

	if t < start_light_t:
		# 白天，没到点亮时间
		base_energy = 0.0
	elif t < full_light_t:
		# 黄昏，慢慢亮起
		var dusk_t = (t - start_light_t) / (full_light_t - start_light_t)
		base_energy = clamp(dusk_t, 0.0, 1.0) * max_energy
	elif t < start_dim_t:
		# 夜晚，保持满亮度
		base_energy = max_energy
	elif t < fully_off_t:
		# 清晨，慢慢熄灭
		var dawn_t = (t - start_dim_t) / (fully_off_t - start_dim_t)
		base_energy = (1.0 - dawn_t) * max_energy
	else:
		# 回到白天，完全熄灭
		base_energy = 0.0

	flicker_time += delta * flicker_speed
	# 篝火：正弦 + 随机脉冲，时不时窜一下火苗
	var wave = sin(flicker_time) * flicker_strength
	var pulse = flicker_rng.randf_range(-flicker_strength * 0.7, flicker_strength * 1.2)
	var flicker = wave + pulse
	
	target_energy = max(0.0, base_energy + flicker)
	energy = lerp(energy, target_energy, delta * transition_speed)
