extends Control

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0,0,0,0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	move_child(bg, 0) # 放到第0位，渲染在所有子节点底层
	visible = false

func open():
	visible = true
	GameState.game_paused = true
	print("暂停打开")

func close():
	visible = false
	GameState.game_paused = false
	print("✅ 继续游戏触发")
