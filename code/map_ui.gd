extends Panel

@export var map_textures:Array[Texture2D] = []
@export var current_area_index:int = 0

@onready var map_image:TextureRect = $MapImage#1#!F

func _ready():
	hide()

func _input(event):
	if Input.is_action_just_pressed("map_toggle") or Input.is_action_just_pressed("map_quit"):
		visible = !visible
		get_viewport().set_input_as_handled()


func refresh_map():
	if map_textures.is_empty():
		return
	map_image.texture = map_textures[current_area_index]
