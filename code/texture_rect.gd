extends TextureRect

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var shake_threshold: int = 30
@export var shake_strength: float = 1.85
@export var shake_speed: float = 100.0

var shake_offset: Vector2 = Vector2.ZERO
var base_local: Vector2

@export var tex_full: Texture2D
@export var tex_high: Texture2D
@export var tex_mid: Texture2D
@export var tex_low: Texture2D

func _ready():
	base_local = position

	# 直接连信号（GameState 是 Autoload，_ready 时通常已存在）
	if GameState != null:
		GameState.hp_changed.connect(_on_hp_changed)
		# 初始同步一次
		_on_hp_changed(GameState.hp, GameState.max_hp)
	else:
		push_error("GameState 单例没找到！")

	update_texture()

func _on_hp_changed(hp: int, hp_max: int):
	current_hp = clamp(hp, 0, hp_max)
	max_hp = hp_max
	update_texture()

func _process(_delta):
	if current_hp < shake_threshold and current_hp > 0:
		var t = Time.get_ticks_msec() * shake_speed * 0.001
		shake_offset.x = sin(t) * shake_strength
		shake_offset.y = cos(t) * shake_strength
	else:
		shake_offset = Vector2.ZERO
	position = base_local + shake_offset

func set_hp(hp: int, hp_max: int):
	current_hp = clamp(hp, 0, hp_max)
	max_hp = hp_max
	update_texture()

func reset_position():
	position = base_local

func update_texture():
	if max_hp <= 0:
		return
	var ratio = float(current_hp) / float(max_hp)
	if ratio > 0.75:
		texture = tex_full
	elif ratio > 0.5:
		texture = tex_high
	elif ratio > 0.25:
		texture = tex_mid
	else:
		texture = tex_low
