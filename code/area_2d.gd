extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines:PackedStringArray = [
"【路标】东方森林",
"警告：大量史莱姆在此游荡。",
"镇子遭遇的怪物就是从这里出现。"
]
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var player = get_node_or_null("../Player")
		var can_trigger = true
		if player != null and GameState != null:
			can_trigger = (GameState.story_progress >= 1)
		
		if in_range and not is_dialog and can_trigger:
			start()
		elif is_dialog:
			if dialog_box.is_typing_done():
				next_line()
			else:
				dialog_box.skip_typing()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		print("【Area2D】玩家进入碰撞区")
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键交互"
			hint_label.visible = true

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

func start():
	if GameState.game_paused:
		return

	if dialog_box == null:
		print("⚠️路标没有设置dialog_box引用！")
		return
	is_dialog = true
	current_line = 0
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
	dialog_box.show_dialog(lines[current_line])
	if hint_label != null:
		hint_label.visible = false

func next_line():
	current_line +=1
	if current_line >= lines.size():
		is_dialog = false
		current_line = 0
		dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null:
			player.can_move = true
	else:
		dialog_box.show_dialog(lines[current_line])
