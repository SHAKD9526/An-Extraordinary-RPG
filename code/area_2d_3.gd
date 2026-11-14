extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines:PackedStringArray = [
"[西方公路路牌]",
"*要不还是别管那些人了吧，还是赶紧走比较好，毕竟连自身安危都没有办法确保。",
"*我到这里游历就是一个错误",
"西方公路与维伦城比较近，还是赶紧回城里吧"
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
		var can_trigger = false
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
		print("⚠️西方公路路牌没有设置dialog_box引用！")
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
