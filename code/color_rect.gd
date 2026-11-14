extends Control
@export var player: Node2D
@export var dialog_font: FontFile
@export var typing_interval: float = 0.05 # 每个字间隔，越小越快
@export var pause_on_punct: float = 0.09 # 遇到标点停顿更久

var bg: ColorRect
var text_label: Label

var full_text: String = ""
var display_text: String = ""
var char_index: int = 0
var timer: float = 0.0
var typing: bool = false

func _ready():
	visible = false
	# 根节点自己贴底部、左右占满
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# 离底部/左右留边距
	offset_left = 40
	offset_right = -40
	offset_top = -220
	offset_bottom = -24
	# 背景
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.238, 0.617, 0.833, 0.867)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# 文字
	text_label = Label.new()
	text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_label.offset_left = 16
	text_label.offset_top = 16
	text_label.offset_right = -16
	text_label.offset_bottom = -16
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if dialog_font:
		text_label.add_theme_font_override("font", dialog_font)
	text_label.add_theme_font_size_override("font_size", 25)
	text_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	add_child(text_label)
	move_child(bg, 0)
	move_child(text_label, 1)

func _process(delta: float) -> void:
	if GameState.game_paused:
		return
	if not typing:
		return
	# 后面原有打字代码不变
	timer += delta
	var wait = typing_interval
	# 标点加长停顿
	var c = full_text[char_index - 1]
	if c in [".", "。", "！", "!", "？", "?", "，", ",","."] :
		wait = pause_on_punct

	if timer >= wait:
		timer = 0.0
		char_index += 1
		display_text = full_text.substr(0, char_index)
		text_label.text = display_text
		# 更新框高度
		custom_minimum_size = Vector2(0, text_label.get_minimum_size().y + 32)

		if char_index >= full_text.length():
			typing = false

# 外部照旧调用 show_dialog("文字")
func show_dialog(text: String):
	if GameState.game_paused:
		return
	visible = true
	full_text = text
	display_text = ""
	char_index = 0
	timer = 0.0
	typing = true
	text_label.text = ""
	custom_minimum_size = Vector2(0, text_label.get_minimum_size().y + 32)
	if player and player.has_method("lock_player"):
		player.lock_player()


func close_dialog():
	visible = false
	text_label.text = ""
	full_text = ""
	display_text = ""
	typing = false
	if player and player.has_method("unlock_player"):
		player.unlock_player()

# 新增：外部调用，判断当前这段文字是否打完了
func is_typing_done() -> bool:
	return not typing

# 新增：跳过打字机，直接显示全部文字
func skip_typing():
	if not typing:
		return
	typing = false
	display_text = full_text
	text_label.text = full_text
	custom_minimum_size = Vector2(0, text_label.get_minimum_size().y + 32)
