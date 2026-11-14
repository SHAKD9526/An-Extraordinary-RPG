extends Area2D
@export var dialog_box:Control
@export var hint_label:Label

var in_range:bool = false
var is_dialog:bool = false
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(delta):
	var player = get_node_or_null("../Player")
	if player == null or GameState == null:
		return

	if Input.is_action_just_pressed("ui_accept"):
		if in_range and not is_dialog:
			start()
		elif is_dialog:
			if dialog_box.is_typing_done():
				shop_choose()
			else:
				dialog_box.skip_typing()

func _enter(body:Node2D):
	if body.name == "Player":
		in_range = true
		if hint_label != null:
			hint_label.text = "按空格键交谈"
			hint_label.visible = true

func _exit(body:Node2D):
	if body.name == "Player":
		in_range = false
		if hint_label != null:
			hint_label.visible = false
		if is_dialog:
			is_dialog = false
			dialog_box.close_dialog()
			var player = get_node_or_null("../Player")
			if player != null:
				player.can_move = true

func start():
	if dialog_box == null:
		print("【错误】dialog_box 没有绑定！")
		return
	is_dialog = true
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
	if hint_label != null:
		hint_label.visible = false

	dialog_box.show_dialog("【武器商人】你好。")

func shop_choose():
	is_dialog = false
	dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
