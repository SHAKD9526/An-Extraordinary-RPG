extends TextureRect

@export var max_sprint: float = 25.0
@export var current_sprint: float = 25.0
@export var flash_duration: float = 0.22   # 白光闪烁时长，低频不刺眼
@export var low_threshold: float = 5.0

var flash_timer: float = 0.0
var base_modulate: Color = Color(1,1,1)

# 四段贴图：充足 / 偏低 / 空 / 喘息耗尽
@export var tex_sprint_full: Texture2D
@export var tex_sprint_high: Texture2D
@export var tex_sprint_low: Texture2D
@export var tex_sprint_exhaust: Texture2D

func _ready():
	base_modulate = modulate
	update_texture()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		# 白光渐变消退
		var f = flash_timer / flash_duration
		modulate = Color(1, 1, 1, f)
	else:
		modulate = base_modulate

func set_sprint(val:float, max_val:float, exhausted:bool):
	var old_val = current_sprint
	current_sprint = clamp(val, 0.0, max_val)
	max_sprint = max_val
	
	# 只要数值变了，触发白光闪烁（上升、下降都触发）
	if abs(current_sprint - old_val) > 0.001:
		flash_timer = flash_duration
	
	update_texture(exhausted)

func update_texture(exhausted:bool = false):
	if max_sprint <= 0:
		return
	
	if exhausted:
		texture = tex_sprint_exhaust
		return
	
	var ratio = current_sprint / max_sprint
	if ratio > 0.75:
		texture = tex_sprint_full
	elif ratio > 0.25:
		texture = tex_sprint_high
	else:
		texture = tex_sprint_low
