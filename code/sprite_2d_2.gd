extends Sprite2D#从第一个版本开始废弃
@export var life_time:float = 0

func _ready():
	await get_tree().create_timer(life_time).timeout
	queue_free()
