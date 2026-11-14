extends Area2D
@export var dialog_box:Control
@export var lines:PackedStringArray = [
	"【皇家守卫】：站住！哪里来的？",
	"你：我从蒙驻镇方向过来。",
	"【皇家守卫】：蒙驻镇？那一片早就乱了",
	"【皇家守卫】：算了......你还是进去吧",
]
# 目标传送坐标：西沃城内的出生点
@export var player_spawn_pos:Vector2
@export var delay_time:float = 0.35 # 等待多久才触发对话
@export var require_story_progress:int = 0

var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var GameState:Node = null
var timer:Timer = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")
	# 创建计时器
	timer = Timer.new()
	timer.wait_time = delay_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_ready)
	add_child(timer)

func _enter(body:Node2D):
	if body.name != "Player":
		return
	if is_dialog: # 正在对话就不重新计时
		return
	if require_story_progress > 0 and GameState.story_progress < require_story_progress:
		return
	in_range = true
	timer.start() # 进入，开始倒计时

func _exit(body:Node2D):
	if body.name == "Player":
		in_range = false
		timer.stop() # 离开直接取消计时
		if is_dialog and dialog_box != null:
			is_dialog = false
			current_line = 0
			dialog_box.close_dialog()
			var player = get_node_or_null("../Player")
			if player != null:
				player.can_move = true

func _on_timer_ready():
	# 计时到，启动对话
	var player = get_node_or_null("../Player")
	if player:
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
	dialog_box.show_dialog(lines[current_line])

func next_line():
	current_line += 1
	if current_line >= lines.size():
		end_dialog()
	else:
		dialog_box.show_dialog(lines[current_line])

func end_dialog():
	is_dialog = false
	current_line = 0
	dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
		# 和地道脚本一致：对话全部读完，瞬移
		player.global_position = player_spawn_pos

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and is_dialog:
		if dialog_box.is_typing_done():
			next_line()
		else:
			dialog_box.skip_typing()
