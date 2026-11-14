extends Control
@export var hint_label:Label
var occupied:bool = false

func _ready():
	pass

func _enter_tree():
	if hint_label == null:
		hint_label = get_node_or_null("hint_label")
	
	if hint_label != null:
		hint_label.visible = false
	print("hint_label 获取结果：", hint_label)
	print("✅ Label ready")
	occupied = false

func show_hint(text:String = "按确认键交互"):
	print("=== show_hint 执行 ===")
	#if hint_label == null or occupied:
		#print("被条件拦截，直接return")
		#return
	hint_label.text = text
	hint_label.visible = true
	occupied = true
	print("提示已经打开，text=",hint_label.text)

func hide_hint():
	if hint_label == null:
		return
	hint_label.visible = false
	hint_label.text = ""
	occupied = false
	print("提示隐藏，occupied置false")
