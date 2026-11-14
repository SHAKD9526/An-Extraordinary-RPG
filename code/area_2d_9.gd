extends Area2D
# 挂载了你自定义脚本的对话框节点（继承Control）
@export var dialog_box:Control
@export var hint_label:Label
# NPC对话内容
@export var lines:PackedStringArray = [
	"你:这里有个急救包！",
	"(放进了背包)",
	"*看起来是别人遗留在这里的补给，但我得赶紧去找乔格里里奥！",
]

# 需要达到该剧情进度才可以触发对话，0代表无限制
@export var require_story_progress:int = 1
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
# 标记：只拾取一次急救包，防止重复刷道具
var already_give_kit:bool = false
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
			if player and GameState and in_range and not is_dialog and GameState.story_progress >= require_story_progress and not already_give_kit:
				start()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog and not already_give_kit:
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

	if dialog_box == null or GameState == null:
		print("⚠️未绑定dialog_box！或者找不到GameState")
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
			#对话全部结束，给予急救包，仅执行一次
			if not already_give_kit:
				# 直接操作GameState背包，不要调用player.add_item
				var found:bool = false
				for item in GameState.inventory:
					if item.name == "急救包":
						item.count += 1
						found = true
						break
				if not found:
					GameState.inventory.append({"name":"急救包","count":1})
				already_give_kit = true
				print("✅获得急救包")
		#拿完道具，永久关闭交互提示
		if hint_label != null:
			hint_label.visible = false
		queue_free()
	else:
		dialog_box.show_dialog(lines[current_line])
