extends Label

func _ready():
	text = "死亡：%d" % GameState.die
	GameState.die_changed.connect(_on_die_update)

func _on_die_update(new_val: int):
	text = "死亡：%d" % new_val
