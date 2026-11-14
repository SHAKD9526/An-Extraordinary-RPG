extends GPUParticles2D

enum Weather { CLEAR, RAIN }
@export var current_weather: Weather = Weather.CLEAR
@export var rain_target_strength: float = 0.0
@export var rain_strength: float = 0.0
@export var rain_transition_speed: float = 0.25
@export var weather_check_interval: float = 22.0
@export var rain_chance: float = 0.12
@export var min_rain: float = 0.25
@export var max_rain: float = 0.85

var weather_timer: float = 0.0

func _process(delta):
	weather_timer += delta
	# 平滑过渡雨强度
	rain_strength = lerp(rain_strength, rain_target_strength, delta * rain_transition_speed)
	amount_ratio = rain_strength
	emitting = rain_strength > 0.01

	# 全局调用自动加载的音效管理器，跨场景生效
	var sfx_manager = get_node_or_null("/root/SoundManager")
	if sfx_manager != null:
		sfx_manager.set_rain_volume(rain_strength)

	# 定时随机判定，全天随时可能下雨
	if weather_timer > weather_check_interval:
		weather_timer = 0.0
		var r = randf()
		if r < rain_chance:
			current_weather = Weather.RAIN
			rain_target_strength = randf_range(min_rain, max_rain)
		else:
			current_weather = Weather.CLEAR
			rain_target_strength = 0.0

# 给外部调用的接口（剧情/区域触发下雨用）
func set_rain_strength(target: float):
	rain_target_strength = clamp(target, 0.0, 1.0)
