extends Area2D

var vel := Vector2.ZERO
var life := 6.0

func _physics_process(delta):
	global_position += vel * delta
	life -= delta
	if life <= 0:
		queue_free()

func kill():
	queue_free()
