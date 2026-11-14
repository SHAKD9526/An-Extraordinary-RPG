extends Area2D
@export var dialog_box:Control
@export var normal_lines:PackedStringArray = [
	"*我可不想出去,西沃城那么安全",
]
@export var annoyed_lines:PackedStringArray = [
	"*你没完没了了是吧？",
]
@export var player_spawn_pos:Vector2
@export var delay_time:float = 1.0 # 停留多久触发对话
@export var time_window:float = 60.0 # 统计窗口时长（秒）
@export var trigger_limit:int = 4 # 多少次触发不耐烦台词
@export var require_story_progress:int = 0

var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var GameState:Node = null
var timer:Timer = null
var just_triggered:bool = false

# 次数统计相关
var touch_count:int = 0
var window_timer:Timer = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")
	# 等待触发的计时器
	timer = Timer.new()
	timer.wait_time = delay_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_ready)
	add_child(timer)
	# 计数窗口计时器，时间到清空次数
	window_timer = Timer.new()
	window_timer.wait_time = time_window
	window_timer.one_shot = true
	window_timer.timeout.connect(_reset_count)
	add_child(window_timer)

func _reset_count():
	touch_count = 0
	print("计数窗口结束，对话次数清零")

func _enter(body:Node2D):
	if body.name != "Player":
		return
	if is_dialog:
		return
	if just_triggered:
		return
	if require_story_progress > 0 and GameState.story_progress < require_story_progress:
		return

	in_range = true
	timer.start()

func _exit(body:Node2D):
	if body.name == "Player":
		in_range = false
		timer.stop()
		just_triggered = false
		if is_dialog and dialog_box != null:
			is_dialog = false
			current_line = 0
			dialog_box.close_dialog()
			var player = get_node_or_null("../Player")
			if player != null:
				player.can_move = true

func _on_timer_ready():
	var player = get_node_or_null("../Player")
	if player:
		# ✅ 在这里计数：成功触发对话才+1
		touch_count += 1
		print("对话触发次数：", touch_count)
		if window_timer.is_stopped():
			window_timer.start()
		start(player)

func start(player):
	if GameState.game_paused:
		return

	if is_dialog:
		return
	is_dialog = true
	in_range = true
	current_line = 0
	player.can_move = false
	# 判断用哪套台词
	var use_lines:PackedStringArray
	if touch_count >= trigger_limit:
		use_lines = annoyed_lines
	else:
		use_lines = normal_lines
	dialog_box.show_dialog(use_lines[current_line])

func next_line():
	var use_lines:PackedStringArray
	if touch_count >= trigger_limit:
		use_lines = annoyed_lines
	else:
		use_lines = normal_lines

	current_line += 1
	if current_line >= use_lines.size():
		end_dialog()
	else:
		dialog_box.show_dialog(use_lines[current_line])

func end_dialog():
	is_dialog = false
	current_line = 0
	dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
		player.global_position = player_spawn_pos
		just_triggered = true

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and is_dialog:
		if dialog_box.is_typing_done():
			next_line()
		else:
			dialog_box.skip_typing()
