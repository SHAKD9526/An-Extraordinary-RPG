extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines:PackedStringArray = [
"【埃皮尔超市告示】",
"通知：本超市每周三打烊清理，当天不接待客人，其余时间正常营业。"
]
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		if in_range and not is_dialog:
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
			hint_label.text = "按空格键查看告示"
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
		if is_dialog:
			close_dialog()

func next_line():
	current_line +=1
	if current_line >= lines.size():
		close_dialog()
	else:
		dialog_box.show_dialog(lines[current_line])

func close_dialog():
	is_dialog = false
	current_line = 0
	if dialog_box != null:
		dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
		player.in_dialogue = false
