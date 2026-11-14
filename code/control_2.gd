extends Control
@export var game_scene:PackedScene
@export var game_scene_2:PackedScene

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var bgm = get_node_or_null("/root/AudioStreamPlayer2d")
	print("BGM节点 = ", bgm)

func start_game():
	var bgm = get_node_or_null("/root/AudioStreamPlayer2d")
	if bgm:
		bgm.stop_bgm()
	get_tree().change_scene_to_packed(game_scene)

func start_game_2():
	var bgm = get_node_or_null("/root/AudioStreamPlayer2d")
	if bgm:
		bgm.stop_bgm()
	get_tree().change_scene_to_packed(game_scene_2)

func back_to_main():
	var main_menu = load("res://gameUI.tscn")
	if main_menu != null:
		get_tree().change_scene_to_packed(main_menu)

func _on_finished() -> void:
	pass
