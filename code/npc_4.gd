extends Area2D
@export var dialog_box:Control
@export var hint_label:Label

# 商品配置：
# item_name = 商店显示名称
# real_item_name = 背包物品名
# add_count = 本次购买增加数量
@export var shop_goods:Array[Dictionary] = [
	{"item_name":"手枪", "real_item_name":"手枪", "add_count":1, "price":360, "once_only":true},
	{"item_name":"手枪子弹x10", "real_item_name":"手枪子弹", "add_count":10, "price":17, "once_only":false, "max_buy":10},
	{"item_name":"武士刀", "real_item_name":"武士刀", "add_count":1, "price":180, "once_only":true},
]

var in_range:bool = false
var is_dialog:bool = false
var GameState:Node = null

var buy_record:Dictionary = {
	"手枪":0,
	"手枪子弹x10":0,
	"武士刀":0,
}

var buy_count: int = 0
var window_start: float = 0.0
var is_all_out_of_stock: bool = false
const TIME_WINDOW: float = 60.0
const MAX_BUY_IN_WINDOW: int = 10

func _ready():
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	GameState = get_tree().root.get_node_or_null("GameState")

# 和垃圾桶一模一样的堆叠添加函数
func add_item_stack(item_name:String, add_cnt:int):
	for item in GameState.inventory:
		if item.name == item_name:
			item.count += add_cnt
			return
	GameState.inventory.append({"name": item_name, "count": add_cnt})

func _process(_delta):
	if GameState.game_paused:
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
				next_line()
			else:
				dialog_box.skip_typing()

	if is_dialog and dialog_box.is_typing_done():
		for i in range(shop_goods.size()):
			if Input.is_action_just_pressed("ui_%d" % (i+1)):
				var goods = shop_goods[i]
				var show_name = goods["item_name"]
				var real_name = goods["real_item_name"]
				var cnt = goods["add_count"]
				
				if is_all_out_of_stock:
					dialog_box.show_dialog("【武器商人】货暂时卖光了，给我滚开!别买了!")
					return
				if goods["once_only"] and buy_record[show_name] >= 1:
					dialog_box.show_dialog("【武器商人】这个你已经买过了。")
					return
				if not goods["once_only"] and buy_record[show_name] >= goods["max_buy"]:
					dialog_box.show_dialog("【武器商人】子弹库存已经卖完了。")
					return

				if GameState.gold >= goods["price"]:
					GameState.gold -= goods["price"]
					GameState.gold_changed.emit(GameState.gold)
					add_item_stack(real_name, cnt)
					buy_record[show_name] += 1
					if window_start == 0.0:
						window_start = now
					buy_count += 1
					if buy_count >= MAX_BUY_IN_WINDOW:
						is_all_out_of_stock = true
					dialog_box.show_dialog("【武器商人】拿好你的%s。" % show_name)
				else:
					dialog_box.show_dialog("【武器商人】没钱还想买东西?给我滚蛋!")
				return
		if Input.is_action_just_pressed("ui_%d" % (shop_goods.size()+1)):
			close_shop()

func _enter(body:Node2D):
	if body.name == "Player" and not in_range:
		print("【Area2D】玩家进入碰撞区")
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
				player.in_dialogue = false

func start():
	if dialog_box == null:
		push_error("⚠️武器商人没有设置dialog_box引用！")
		return
	is_dialog = true
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = false
		player.in_dialogue = true
	if hint_label != null:
		hint_label.visible = false

	var has_blood_knife = false
	for item_dict in GameState.inventory:
		if item_dict.name == "血色小刀":
			has_blood_knife = true
			break
	if not has_blood_knife:
		add_item_stack("血色小刀", 1)

	var menu_text = "【武器商人】看看要什么武器？\n"
	if not has_blood_knife:
		menu_text = "【武器商人】这件东西就送给你了，我是从一个镇上捡的。这东西对我没什么用。\n"
	for i in range(shop_goods.size()):
		var g = shop_goods[i]
		menu_text += "%d. %s —— %d金币\n" % [i+1, g["item_name"], g["price"]]
	menu_text += "%d. 离开商店" % [shop_goods.size()+1]
	dialog_box.show_dialog(menu_text)

func next_line():
	close_shop()

func close_shop():
	is_dialog = false
	dialog_box.close_dialog()
	var player = get_node_or_null("../Player")
	if player != null:
		player.can_move = true
		player.in_dialogue = false
