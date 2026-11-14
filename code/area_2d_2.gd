extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines:PackedStringArray = [
"[公告栏]蒙驻小镇",
"4月‑20日,东方森林防线将会由皇家军队为首展开防线建设工作，大家以后不用担心东方森林的安全问题",
"6月‑27日,各位公民们，大家好,前几日，东方森林防线失守,专家推测，史莱姆可能已经到达我们小镇附近,请大家保持警惕。",
"内心:太糟糕了，我只是到处游历，没想到会撞到这种事，我又不是什么勇者。要不我还是赶紧往西边回去吧。",
"6月‑28日，各位公民们，大家好。今日杰克哈马顿闯入东方森林，并携带小刀进入。如有线索，请与我们告知。"
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
			can_trigger = (GameState.story_progress >= 0)
		
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
		print("⚠️公告栏没有设置dialog_box引用！")
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
