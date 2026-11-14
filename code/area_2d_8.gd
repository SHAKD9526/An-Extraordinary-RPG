extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var one_1:float = 0
# 第一次在出口交互的对话
@export var dialog_lines_first:PackedStringArray = [
"*地道的出口，从这里出去回到森林另一侧。",
"*地道可以绕开地面游荡的史莱姆，里面昏暗潮湿。",
"【按确认键：进入地道返回】"
]
# 重复来访对话
@export var dialog_lines_after:PackedStringArray = [
"*潮湿的地道出口，可以抄近路回到另一边。",
]
# 【重点】这里填【地道入口A】的坐标，传回去
@export var player_spawn_pos:Vector2
# 剧情锁保持一样，同样需要读完士兵日记才能用
@export var require_story_progress:int = 1
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var active_dialog:PackedStringArray = []
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		var player = get_node_or_null("../Player")
		if player == null or GameState == null:
			return
		
		#剧情不达标拦截
		if GameState.story_progress < require_story_progress:
			if in_range and not is_dialog:
				if hint_label != null:
					hint_label.text = "洞口被土石堵住，暂时无法进入"
			return
		if in_range and not is_dialog:
			start(player)
		elif is_dialog:
			if dialog_box.is_typing_done():
				next_line()
			else:
				dialog_box.skip_typing()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog:
			if GameState != null and GameState.story_progress < require_story_progress:
				hint_label.text = "洞口被土石堵住，暂时无法进入"
			else:
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

func start(player):
	if GameState.game_paused:
		return

	if dialog_box == null:
		return
	is_dialog = true
	current_line = 0
	player.can_move = false
	if hint_label != null:
		hint_label.visible = false
	if one_1 == 0:
		active_dialog = dialog_lines_first
	else:
		active_dialog = dialog_lines_after
	
	dialog_box.show_dialog(active_dialog[current_line])

func next_line():
	current_line +=1
	if current_line >= active_dialog.size():
		is_dialog = false
		current_line = 0
		dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null:
			player.can_move = true
			if one_1 == 0:
				one_1 = 1
			# 瞬移回地道入口A的坐标
			player.global_position = player_spawn_pos
	else:
		dialog_box.show_dialog(active_dialog[current_line])
