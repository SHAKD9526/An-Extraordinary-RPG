extends CharacterBody2D

@export var soul_speed := 300.0
var invuln := 0.0
signal hurt(dmg:int)

@onready var hitbox:Area2D = $Hitbox

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hitbox.area_entered.connect(_on_hit)

func _physics_process(delta):
	var dir := Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = dir * soul_speed
	move_and_slide()

	if invuln > 0:
		invuln -= delta
		modulate.a = 0.5
	else:
		modulate.a = 1.0

func _on_hit(area):
	if invuln > 0: return
	if area.is_in_group("enemy_bullet"):
		invuln = 0.8
		hurt.emit(3)
		if area.has_method("kill"):
			area.kill()
		else:
			area.queue_free()
