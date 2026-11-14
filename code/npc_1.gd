extends Area2D
@export var dialog_box:Control
@export var hint_label:Label

# 商品配置
@export var shop_goods:Array[Dictionary] = [
	{"item_name":"手枪", "price":60, "once_only":true},
	{"item_name":"手枪子弹x10", "price":12, "once_only":false, "max_buy":10},
	{"item_name":"武士刀", "price":80, "once_only":true},
]

var in_range:bool = false
var is_dialog:bool = false
var GameState:Node = null

# 购买次数记录
var buy_record:Dictionary = {
	"手枪":0,
	"手枪子弹x10":0,
	"武士刀":0,
}

# ===== 缺货逻辑（和前面两个商店保持一致）=====
var buy_count: int = 0
var window_start: float = 0.0
var is_all_out_of_stock: bool = false
const TIME_WINDOW: float = 60.0
const MAX_BUY_IN_WINDOW: int = 10
# =============================================

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

func _process(_delta):
	var player = get_node_or_null("../Player")
	if player == null or GameState == null:
		return

	var now = Time.get_ticks_msec() / 1000.0
	if window_start > 0 and now - window_start > TIME_WINDOW:
		buy_count = 0
		window_start = 0.0
		is_all_out_of_stock = false
	
	if Input.is_action_just_pressed("ui_accept"):
		if in_range and not is_dialog:
			start()
		elif is_dialog:
			if dialog_box.is_typing_done():
				shop_choose()
			else:
				dialog_box.skip_typing()
	
	if is_dialog and dialog_box.is_typing_done():
		for i in range(shop_goods.size()):
			if Input.is_action_just_pressed("ui_%d" % (i+1)):
				var goods = shop_goods[i]
				var item_name = goods["item_name"]
				if is_all_out_of_stock:
					dialog_box.show_dialog("【武器商人】货暂时卖光了，给我滚开!别买了!")
					return
				if goods["once_only"] and buy_record[item_name] >= 1:
					dialog_box.show_dialog("【武器商人】这个你已经买过了。")
					return
				if not goods["once_only"] and buy_record[item_name] >= goods["max_buy"]:
					dialog_box.show_dialog("【武器商人】子弹库存已经卖完了。")
					return

				if GameState.spend_gold(goods["price"]):
					GameState.global_add_item(item_name, 1)
					buy_record[item_name] += 1
					if window_start == 0.0:
						window_start = now
					buy_count += 1
					if buy_count >= MAX_BUY_IN_WINDOW:
						is_all_out_of_stock = true
					dialog_box.show_dialog("【武器商人】拿好你的%s。" % item_name)
				else:
					dialog_box.show_dialog("【武器商人】没钱还想买东西?给我滚蛋!")
				return
		if Input.is_action_just_pressed("ui_%d" % (shop_goods.size()+1)):
			shop_choose()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		in_range = true
		if hint_label != null and not is_dialog:
			hint_label.text = "按空格键和武器商人交谈"
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
		print("⚠️ 武器商人：dialog_box没有赋值！")
		return
	is_dialog = true
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
	if hint_label != null:
		hint_label.visible = false

	var has_blood_knife = false
	for item_dict in GameState.inventory:
		if item_dict.name == "血色小刀":
			has_blood_knife = true
			break
	
	var menu_text = ""
	if not has_blood_knife:
		GameState.global_add_item("血色小刀",1)
		menu_text = "【武器商人】这件东西先给你，收好。看看要什么武器？\n"
	else:
		menu_text = "【武器商人】：看看要什么武器？\n"

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
