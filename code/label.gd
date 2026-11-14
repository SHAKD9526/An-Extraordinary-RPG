extends Label

func _ready():
	var gs = get_tree().root.get_node_or_null("GameState")
	if gs:
		text = "金币：%d" % gs.gold
		gs.gold_changed.connect(_update_gold)

func _update_gold(new_gold:int):
	text = "金币：%d" % new_gold
