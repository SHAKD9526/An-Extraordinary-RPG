extends Area2D
#我仍然使用那台老电脑,只是SATA线有些接触不良
@export var dialog_box:Control
@export var hint_label:Label
@export var require_story_progress:int = 0

# 商品配置：[物品名, 单价]
@export var shop_goods:Array[Dictionary] = [
	{"item_name":"烤肠", "price":10},
]

var in_range:bool = false
var is_dialog:bool = false
var GameState:Node = null
var select_index:int = 0

# ===== 缺货逻辑变量 =====
var buy_count: int = 0
var window_start: float = 0.0
var is_all_out_of_stock: bool = false
const TIME_WINDOW: float = 60.0
const MAX_BUY_IN_WINDOW: int = 10
# ========================

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(_delta):
	var player = get_node_or_null("../Player")
	if player == null or GameState == null:
		return
	
	# 自动检查计时窗口是否过期，超时重置计数和缺货状态
	var now = Time.get_ticks_msec() / 1000.0
	if window_start > 0 and now - window_start > TIME_WINDOW:
		buy_count = 0
		window_start = 0.0
		is_all_out_of_stock = false

	if Input.is_action_just_pressed("ui_accept"):
		if GameState.story_progress < require_story_progress:
			return
		if in_range and not is_dialog:
			start()
		elif is_dialog:
			if dialog_box.is_typing_done():
				shop_choose()
			else:
				dialog_box.skip_typing()
	
	# 商店打开时，数字按键选购
	if is_dialog and dialog_box.is_typing_done():
		for i in range(shop_goods.size()):
			if Input.is_action_just_pressed("ui_%d" % (i+1)):
				var goods = shop_goods[i]
				# 【缺货判断】全部商品统一缺货
				if is_all_out_of_stock:
					dialog_box.show_dialog("【小贩】货暂时卖光了，给我滚开!别买了!")
					return
				if GameState.spend_gold(goods["price"]):
					GameState.global_add_item(goods["item_name"], 1)
					# 成功购买，计数+1
					if window_start == 0.0:
						window_start = now
					buy_count += 1
					if buy_count >= MAX_BUY_IN_WINDOW:
						is_all_out_of_stock = true
					dialog_box.show_dialog("【小贩】拿好你的%s" % goods["item_name"])
				else:
					dialog_box.show_dialog("【小贩】没钱还想买东西?给我滚开!")
				return
		# 最后一项：离开
		if Input.is_action_just_pressed("ui_%d" % (shop_goods.size()+1)):
			shop_choose()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键和商人交谈"
			hint_label.visible = true

func _exit(body:Node2D):
	if body.name == "Player":
		in_range = false
		if hint_label != null:
			hint_label.visible = false
		if is_dialog and dialog_box != null:
			is_dialog = false
			dialog_box.close_dialog()
			var player = get_node_or_null("../Player")
			if player != null:
				player.can_move = true

func start():
	if GameState.game_paused:
		return

	if dialog_box == null:
		return
	is_dialog = true
	select_index = 0
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
	if hint_label != null:
		hint_label.visible = false
	
	# 拼商店菜单文本
	var menu_text = "【小贩】：快来买好吃又好看的烤肠咯!\n"
	for i in range(shop_goods.size()):
		var g = shop_goods[i]
		menu_text += "%d. %s —— %d金币\n" % [i+1, g["item_name"], g["price"]]
	menu_text += "%d. 离开商店" % [shop_goods.size()+1]
	dialog_box.show_dialog(menu_text)

func shop_choose():
	is_dialog = false
	dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
