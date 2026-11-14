extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines:PackedStringArray = [
"*一把废弃在这里的小刀上面沾了很多血，估计是某个战士留下的，现在恐怕已经遭遇不测了，我还是赶紧离开这里吧。",
"(拾起了小刀)*看起来挺锋利，可以当武器使用。似乎还有些沉重。"
]
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var has_taken:bool = false
var GameState:Node = null

func _ready():
	GameState = get_tree().root.get_node_or_null("GameState")
	body_entered.connect(_enter)
	body_exited.connect(_exit)

func _process(_delta):
	if has_taken:
		return
	if Input.is_action_just_pressed("ui_accept"):
		if in_range and not is_dialog:
			start()
		elif is_dialog:
			if dialog_box.is_typing_done():
				next_line()
			else:
				dialog_box.skip_typing()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range and not has_taken:
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键交互"
			hint_label.visible = true

func start():
	if GameState.game_paused:
		return

	if dialog_box == null:
		print("没有设置dialog_box引用！")
		return
	is_dialog = true
	current_line = 0
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
		player.in_dialogue = true
	dialog_box.show_dialog(lines[current_line])
	if hint_label != null:
		hint_label.visible = false

func _exit(body:Node2D):
	if body.name == "Player":
		in_range = false
		if hint_label != null:
			hint_label.visible = false
		if is_dialog and dialog_box != null:
			is_dialog = false
			current_line = 0
			dialog_box.close_dialog()
			var player = get_node_or_null("../Player")
			if player != null:
				player.can_move = true
				player.in_dialogue = false

func next_line():
	current_line +=1
	if current_line >= lines.size():
		is_dialog = false
		current_line = 0
		if dialog_box != null:
			dialog_box.close_dialog()
		has_taken = true
		var player = get_node_or_null("../Player")
		if GameState != null:
			GameState.global_add_item("血色小刀", 1)
			GameState.equipped_weapon = "血色小刀"
			print("✅获得血色小刀，并自动装备")
		if player != null:
			player.equip_weapon("血色小刀")
			player.can_move = true
			player.in_dialogue = false
		queue_free()
	else:
		dialog_box.show_dialog(lines[current_line])
