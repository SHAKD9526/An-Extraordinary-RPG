extends Camera2D

# 受伤震屏参数
@export var shake_strength_light: float = 8.5
@export var shake_strength_heavy: float = 16.5
@export var shake_duration: float = 0.10

# 攻击命中震屏（单独强度）
@export var hit_shake_strength: float = 16.0
@export var hit_shake_duration: float = 0.12
# 空挥震屏（没打到敌人）
@export var swing_shake_strength: float = 8.0
@export var swing_shake_duration: float = 0.12

# 奔跑摇晃参数
@export var run_shake_strength: float = 3
@export var run_shake_speed: float = 3.0
@export var player: CharacterBody2D = null

# 受伤收缩参数
@export var hurt_zoom_scale: float = 1.12
@export var hurt_zoom_recover_speed: float = 4.0

# 受伤震屏
var hurt_shake_timer: float = 0.0
var hurt_shake_add: Vector2 = Vector2.ZERO
var hurt_current_strength: float = 0.0

# 攻击震屏（独立，不关联缩放）
var hit_shake_timer: float = 0.0
var hit_shake_add: Vector2 = Vector2.ZERO
var hit_current_strength: float = 0.0

# 奔跑噪声变量
var noise: FastNoiseLite
var noise_time: float = 0.0
var run_shake_offset: Vector2 = Vector2.ZERO

# 受伤缩放变量
var base_zoom: Vector2
var hurt_zoom: Vector2

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.2
	base_zoom = zoom
	hurt_zoom = base_zoom

# 玩家受伤：震屏 + 镜头收缩
func hurt_player(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	hurt_current_strength = shake_strength_light
	hurt_shake_timer = shake_duration
	hurt_zoom = base_zoom * hurt_zoom_scale

func hurt_heavy(direction: Vector2, combo_mul: float):
	if direction == Vector2.ZERO:
		return
	hurt_current_strength = shake_strength_heavy * combo_mul
	hurt_shake_timer = shake_duration
	hurt_zoom = base_zoom * hurt_zoom_scale

# 攻击命中敌人：只震屏，完全不碰缩放
func hit_enemy(direction: Vector2, combo_mul: float = 1.0):
	if direction == Vector2.ZERO:
		return
	hit_current_strength = hit_shake_strength * combo_mul
	hit_shake_timer = hit_shake_duration


func _process(delta):
	# ===== 受伤震屏计算 =====
	if hurt_shake_timer > 0:
		hurt_shake_timer -= delta
		var power = hurt_current_strength * (hurt_shake_timer / shake_duration)
		var rand_vec = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		hurt_shake_add = rand_vec * power
	else:
		hurt_shake_add = Vector2.ZERO

	# ===== 攻击震屏计算（这里修好） =====
	if hit_shake_timer > 0:
		hit_shake_timer -= delta
		var power = hit_current_strength * (hit_shake_timer / hit_shake_duration)
		var rand_vec = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		hit_shake_add = rand_vec * power
	else:
		hit_shake_add = Vector2.ZERO

	# ===== 奔跑摇晃 =====
	var target_run_shake = Vector2.ZERO
	if player != null:
		var is_moving = player.velocity.length() > 0.1
		if is_moving:
			noise_time += delta * run_shake_speed
			var nx = noise.get_noise_2d(noise_time, 0)
			var ny = noise.get_noise_2d(0, noise_time)
			target_run_shake = Vector2(nx, ny) * run_shake_strength
	
	run_shake_offset = run_shake_offset.move_toward(target_run_shake, 8.0)

	# 总偏移叠加
	offset = hurt_shake_add + hit_shake_add + run_shake_offset

	# ===== 受伤缩放（只受 hurt_player / hurt_heavy 控制） =====
	hurt_zoom = hurt_zoom.move_toward(base_zoom, hurt_zoom_recover_speed * delta)
	zoom = hurt_zoom

# 空挥，没打中敌人，震动更小
func swing_miss(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	hit_current_strength = swing_shake_strength
	hit_shake_timer = swing_shake_duration
