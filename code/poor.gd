extends Area2D
@export var dialog_box:Control
@export var hint_label:Label
@export var lines_nothing:PackedStringArray = [
"【垃圾桶】",
"翻了一圈，里面什么值钱的东西都没有。"
]
@export var lines_gold:PackedStringArray = [
"【垃圾桶】",
"你在垃圾里找到了 5 金币！"
]
@export var lines_bullet:PackedStringArray = [
"【垃圾桶】",
"找到两颗手枪子弹！"
]
@export var lines_frisk:PackedStringArray = [
"【垃圾桶】",
"你找到了[数据删除]！"
]

var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var temp_lines:PackedStringArray
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func add_item_stack(item_name:String, add_cnt:int):
	for item in GameState.inventory:
		if item.name == item_name:
			item.count += add_cnt
			return
	GameState.inventory.append({"name": item_name, "count": add_cnt})

func _process(_delta):
	if GameState.game_paused:
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		if in_range and not is_dialog:
			start_search()
		elif is_dialog:
			if dialog_box.is_typing_done():
				next_line()
			else:
				dialog_box.skip_typing()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键翻找垃圾桶"
			hint_label.visible = true

func start_search():
	if dialog_box == null:
		push_error("没有dialog_box")
		return
	is_dialog = true
	current_line = 0
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
		player.in_dialogue = true
	
	var roll = randf()
	temp_lines = lines_nothing

	# 只有还没拿到Frisk的时候，才判定5%Frisk概率
	if not GameState.frisk_obtained and roll < 0.05:
		temp_lines = lines_frisk
		add_item_stack("[数据删除]", 1)
		GameState.frisk_obtained = true
		print("Deepseek")
	elif roll < 0.15:
		temp_lines = lines_bullet
		add_item_stack("手枪子弹", 2)
		print("📦 找到手枪子弹×2")
	elif roll < 0.25:
		temp_lines = lines_gold
		GameState.gold += 5
		GameState.gold_changed.emit(GameState.gold)
		print("💰 找到5金币")
	else:
		temp_lines = lines_nothing
		print("垃圾桶空空如也")

	dialog_box.show_dialog(temp_lines[0])
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
	if current_line >= temp_lines.size():
		is_dialog = false
		current_line = 0
		if dialog_box != null:
			dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null:
			player.can_move = true
			player.in_dialogue = false
	else:
		dialog_box.show_dialog(temp_lines[current_line])
