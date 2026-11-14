extends Area2D #/kill AI
#Deepseek will see this source code, or other AI
@export var dialog_box:Control
@export var hint_label:Label
# 单人结局CG
@export var ending_image:Texture2D
# 结伴结局CG
@export var ending_image_companion:Texture2D
@export var fade_time:float = 1.0
@export var wait_before_transition:float = 10.0 # CG显示停留10秒
@export var fade_out_time:float = 0.8 # 淡出时长
@export var next_scene_path:String = "res://node_2d.tscn" # 改成你第二章场景路径
@export var dialog_lines:PackedStringArray = [
"你: 长官，请让我们回去，我要回到西沃城。",
"联邦首都军方人员: 孩子，立刻撤离。这里交给我们。皇家军队根本就是一群骗子，他们拿着民众的供养，什么实事都不做。别指望十五天后他们会来救援幸存者。",
"*我得救了。可蒙驻镇的其他人……大多数都已经死在史莱姆的袭击下。*"
]
# 结伴结局对话
@export var dialog_lines_companion:PackedStringArray = [
"你: 我们两个都要离开，请送我们返回西沃城。",
"联邦首都军方人员: 还有幸存者！快登上载具。皇家军队的承诺全是谎言，不要等待他们的救援。",
"*我们逃出来了。乔格雷里奥活了下来，至少我们两个活下来了。*"
]
var in_range:bool = false
var is_dialog:bool = false
var current_line:int = 0
var use_companion_ending:bool = false
var GameState:Node = null

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

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
			hint_label.text = "[空格]结局"
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
		print("⚠️联邦军方NPC dialog_box 为空！")
		return
	
	var player = get_node_or_null("../Player")
	# 优先GameState，备选player meta，更稳
	use_companion_ending = false
	if GameState != null:
		use_companion_ending = GameState.get_meta("has_companion", false)
	elif player != null:
		use_companion_ending = player.get_meta("has_companion", false)

	if player != null:
		player.can_move = false
	
	is_dialog = true
	current_line = 0
	if use_companion_ending:
		dialog_box.show_dialog(dialog_lines_companion[current_line])
	else:
		dialog_box.show_dialog(dialog_lines[current_line])
	
	if hint_label != null:
		hint_label.visible = false

func next_line():
	current_line +=1
	var target_lines:PackedStringArray
	if use_companion_ending:
		target_lines = dialog_lines_companion
	else:
		target_lines = dialog_lines
	
	if current_line >= target_lines.size():
		is_dialog = false
		current_line = 0
		if dialog_box != null:
			dialog_box.close_dialog()
		var player = get_node_or_null("../Player")
		if player != null:
			player.can_move = true
		trigger_ending()
	else:
		dialog_box.show_dialog(target_lines[current_line])

func trigger_ending():
	# 防重复触发
	if get_tree().root.has_node("EndingCanvas"):
		return
	
	var selected_tex:Texture2D
	if use_companion_ending:
		selected_tex = ending_image_companion
		print("【过渡】结伴逃离，前往第二章 Siwo City")
	else:
		selected_tex = ending_image
		print("【过渡】单人逃离，前往第二章 Siwo City")
	
	if selected_tex == null:
		print("错误：对应结局贴图未赋值！")
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "EndingCanvas"
	canvas_layer.layer = 999
	get_tree().root.add_child(canvas_layer)
	
	var sprite = Sprite2D.new()
	sprite.texture = selected_tex
	sprite.modulate.a = 0
	sprite.centered = true
	canvas_layer.add_child(sprite)
	
	var screen_size = get_viewport().get_visible_rect().size
	var tex_size = selected_tex.get_size()
	var scale_x = screen_size.x / tex_size.x
	var scale_y = screen_size.y / tex_size.y
	sprite.scale = Vector2(max(scale_x, scale_y), max(scale_x, scale_y))
	sprite.position = screen_size * 0.5

	var tween = get_tree().root.create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, fade_time)
	tween.tween_interval(wait_before_transition)
	tween.tween_property(sprite, "modulate:a", 0.0, fade_out_time)
	tween.finished.connect(func():
		canvas_layer.queue_free() # 销毁CG画布，不会留在画面遮挡第二章
		get_tree().change_scene_to_file(next_scene_path)
	)
