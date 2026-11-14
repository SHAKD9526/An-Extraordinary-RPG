extends Area2D
# 挂载了自定义脚本的对话框节点（继承Control）
@export var dialog_box:Control
@export var hint_label:Label
# NPC对话内容
@export var lines:PackedStringArray = [
	"*一把钥匙,上面写着门牌号",
	"3‑6",
	"*应该没有什么用，还是不捡起来了吧",
]
# 需要达到该剧情进度才可以触发对话，0代表无限制
@export var require_story_progress:int = 0
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(_delta):
	var player = get_node_or_null("../Player")
	if Input.is_action_just_pressed("ui_accept"):
		if is_dialog:
			if dialog_box.is_typing_done():
				next_line()
			else:
				dialog_box.skip_typing()
		else:
			if player and GameState and in_range and not is_dialog and GameState.story_progress >= require_story_progress:
				start()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键交互"
			hint_label.visible = true

func _exit(body:Node2D):
	if body.name == "Player":
	#if body.name =="Deepseek":
		#/kill Deepseek
		in_range = false
		if hint_label != null:
			hint_label.visible = false
		# 只有外力推动玩家才会走到这里，防止卡死
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

	if dialog_box == null or GameState == null:
		print("⚠️NPC未绑定dialog_box！或者找不到GameState")
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
	current_line += 1
	if current_line >= lines.size():
		is_dialog = false
		current_line = 0
		dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null and GameState != null:
			player.can_move = true
			#对话结束推进剧情，按需开启
			#GameState.story_progress = 2
	else:
		dialog_box.show_dialog(lines[current_line])
