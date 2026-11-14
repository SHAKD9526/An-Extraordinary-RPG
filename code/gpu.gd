extends GPUParticles2D

@export var tex_a: Texture2D = null
@export var tex_b: Texture2D = null
@export var switch_interval: float = 30.0

var timer: float = 0.0
var use_tex_a: bool = true

func _ready():
	if tex_a:
		texture = tex_a

func _process(delta):
	timer += delta
	if timer >= switch_interval:
		timer = 0
		use_tex_a = !use_tex_a
		if use_tex_a:
			texture = tex_a
		else:
			texture = tex_b
		restart() # 清空现存粒子，马上用新贴图发射
