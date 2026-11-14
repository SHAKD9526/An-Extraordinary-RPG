extends Control

var btn_map:Dictionary = {
	"btn_left":"move_left",
	"btn_right":"move_right",
	"btn_up":"move_up",
	"btn_down":"move_down",
	"btn_interact":"ui_accept",
	"btn_attack":"attack",
	"btn_spring":"ui_accept",
	"btn_inventory":"ui_inventory"
}
@export var player:CharacterBody2D
var inv_btn_cd:bool = false
@export var inv_cd_time:float = 0.2

func _ready():
	if Engine.is_editor_hint():
		visible = true
	else:
		visible = OS.has_feature("android")
	print("is android: ", visible)
	
	for child in get_children():
		if child is TextureButton and btn_map.has(child.name):
			var action = btn_map[child.name]
			if action == "ui_inventory":
				child.pressed.connect(_on_inv_pressed)
			else:
				# 固定 action 闭包
				child.button_down.connect(func(act=action): Input.action_press(act))
				child.button_up.connect(func(act=action): Input.action_release(act))

func _on_inv_pressed():
	if inv_btn_cd:
		return
	if not player or not is_instance_valid(player):
		return
	inv_btn_cd = true
	player.toggle_inventory()
	await get_tree().create_timer(inv_cd_time).timeout
	inv_btn_cd = false
