extends StaticBody2D

# 是否可以被主角攻击打碎
@export var breakable:bool = true
# 打碎需要攻击次数
@export var hp:int = 3

func _on_hit():
	if not breakable:
		return
	hp -= 1
	if hp <= 0:
		queue_free()
