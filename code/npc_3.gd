extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
# 第一次对话
@export var lines:PackedStringArray = [
	"守卫：看你这身打扮，刚从外面回来？",
	"你：嗯......是的。",
	"守卫：外面可不太平,我劝你老老实实呆在城里面。",
]
# 第二次对话（第一次说完之后，再交互触发）
@export var lines_second:PackedStringArray = [
	"你：你知道乔格雷里奥和杰克哈马顿吗？",
	"守卫：....... ........",
	"守卫：我不能跟你说。",
]
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var GameState:Node = null
var has_talked_once:bool = false # 标记是否已经完成过一轮对话

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
	# 判断读哪一套台词
	if not has_talked_once:
		dialog_box.show_dialog(lines[current_line])
	else:
		dialog_box.show_dialog(lines_second[current_line])
	if hint_label != null:
		hint_label.visible = false

func next_line():
	current_line +=1
	var target_lines:PackedStringArray
	if not has_talked_once:
		target_lines = lines
	else:
		target_lines = lines_second
	
	if current_line >= target_lines.size():
		is_dialog = false
		current_line = 0
		dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null:
			player.can_move = true
		# 第一轮对话结束后打上标记，下次触发第二套
		if not has_talked_once:
			has_talked_once = true
	else:
		dialog_box.show_dialog(target_lines[current_line])
