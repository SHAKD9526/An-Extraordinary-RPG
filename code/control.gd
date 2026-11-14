extends Control
#问题短暂被掩盖，但根源没有消除；发声的人退场，旧的乱象就慢慢卷土重来。
@export var game_scene:PackedScene

func _ready():
	preload("res://slash_scene.tscn")
	var bgm = get_node_or_null("/root/AudioStreamPlayer2d")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("菜单已加载")

func start_game():
	var bgm = get_node_or_null("/root/AudioStreamPlayer2d")
	print("【点击了开始游戏按钮】")
	get_tree().change_scene_to_packed(game_scene)



func quit_game():
	print("【点击了退出按钮】")
	get_tree().quit()


func _on_finished() -> void:
	pass # Replace with function body.
