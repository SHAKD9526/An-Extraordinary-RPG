extends ColorRect

@export var player_ref: CharacterBody2D = null
var GameState: Node = null
var selected_item_index: int = -1
var is_open: bool = false

func _ready():
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	if player_ref == null:
		push_error("没有传入player_ref")
	
	GameState = get_tree().root.get_node_or_null("GameState")
	if GameState == null:
		push_error("找不到GameState单例！")

	# 分辨率自适应
	set_anchors_preset(Control.PRESET_CENTER)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	custom_minimum_size = Vector2(550, 300)
	size = custom_minimum_size

	if has_node("Panel"):
		$Panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		$Panel.offset_left = 30
		$Panel.offset_top = 30
		$Panel.offset_right = -30
		$Panel.offset_bottom = -30

	$Panel/Button.pressed.connect(_on_close_button_pressed)
	$Panel/ItemList.item_selected.connect(_on_item_click)
	$Panel/DetailLabel.visible = false

	refresh_items()


func refresh_items():
	if GameState == null:
		return
	var item_list = $Panel/ItemList
	item_list.clear()
	for index in range(GameState.inventory.size()):
		var item = GameState.inventory[index]
		if item is Dictionary and item.has("name") and item.has("count"):
			var display_text = "%s ×%d" % [item.name, item.count]
			item_list.add_item(display_text)
	$Panel/DetailLabel.visible = false
	selected_item_index = -1


func _on_item_click(index: int):
	if GameState == null:
		return
	selected_item_index = index
	var item = GameState.inventory[index]
	print("当前选中物品名字：", item.name)
	var detail_text = ""
	var equip_mark = ""
	if player_ref != null and player_ref.equipped_weapon == item.name:
		equip_mark = "\n\n————\n【当前已装备】"

	match item.name:
		"血色小刀":
			detail_text = """【血色小刀】
锋利的小刀,上面沾满了血。
看上去还很新，还能用很久。
比水果刀更锋利一些。
但也更沉重一些。""" + equip_mark
		"面包":
			detail_text = """【面包】
自己做的面包。
放了5天，
应该还能吃。
按空格键使用"""
		"水果刀":
			detail_text = """【水果刀】
出去游历之前从家里拿的。
舍不得扔掉。
有些钝了，但是比较轻快。""" + equip_mark
		"急救包":
			detail_text = """【急救包】
一份应急医疗物资。
剧情关键道具，无法直接使用。"""
		"装着7颗蛋的鸟窝":
			detail_text = """【装着7颗蛋的鸟窝】
一个装着7颗颜色各异的蛋的鸟窝
红,绿,蓝,青,黄,橙,紫色
"""
		"手枪":
			detail_text = """【手枪】
""" + equip_mark
		"[数据删除]":
			detail_text = """
数据删除
"""
		"烤肠":
			detail_text = """【烤肠】
看上去并不是纯肉做的。
但是闻上去很香，
看起来加了不少调料
"""
		"绷带":
			detail_text = """【绷带】
非常劣质的绷带
"""
		"武士刀":#0.0.0.9 New
			detail_text = """【武士刀】
非常强力的武器，虽然不是很锋利，
但是可以越挥越快
"""
		"民用医疗包":
			detail_text = """【民用医疗包】
基础医疗物资，可以恢复生命值。
按空格键使用。"""
		_:
			detail_text = "【%s】\n暂无物品描述" % item.name
	
	$Panel/DetailLabel.text = detail_text
	$Panel/DetailLabel.visible = true


func _process(_delta):
	if not is_instance_valid(self):
		return
	if not is_open:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		_on_close_button_pressed()
	if Input.is_action_just_pressed("ui_accept") and selected_item_index >= 0:
		use_selected_item()


func use_selected_item():
	if GameState == null:
		return
	if selected_item_index < 0 or selected_item_index >= GameState.inventory.size():
		print("use_selected_item：索引无效", selected_item_index)
		selected_item_index = -1
		return
		
	var item = GameState.inventory[selected_item_index]
	var item_name = item.name
	print("尝试使用：", item_name)

	match item_name:
		"面包":
			if GameState.global_consume_item("面包", 1):
				player_ref.available_sprint = min(player_ref.available_sprint + 10, player_ref.max_run_duration)
				GameState.heal(10)
				print("✅ 使用面包成功")
				refresh_items()
			else:
				print("❌ 面包消耗失败")
		"烤肠":
			if GameState.global_consume_item("烤肠",1):
				player_ref.available_sprint = min(player_ref.available_sprint + 15, player_ref.max_run_duration)
				GameState.heal(12)
				refresh_items()
		"绷带":
			if GameState.global_consume_item("绷带", 1):
				GameState.heal(3)
				refresh_items()
		"民用医疗包":
			if GameState.global_consume_item("民用医疗包", 1):
				GameState.heal(25)
				print("✅ 使用医疗包成功")
				refresh_items()
			else:
				print("❌ 医疗包消耗失败")
		"急救包":
			print("急救包：这是留给乔格雷里奥的物资，不能自己使用。")
		"血色小刀","水果刀","手枪","武士刀":
			if GameState.equipped_weapon == item_name:
				print("该武器已经装备")
				return
			player_ref.equip_weapon(item_name)
			refresh_items()





func _on_viewport_resized():
	pass


func open_inventory():
	is_open = true
	refresh_items()
	if player_ref and is_instance_valid(player_ref):
		player_ref.open_inventory()
	# ✅ 新增：背包打开，标记为暂停交互
		GameState.game_paused = true

func _on_close_button_pressed():
	if not is_open:
		return
	is_open = false
	selected_item_index = -1
	$Panel/DetailLabel.visible = false
	if player_ref and is_instance_valid(player_ref):
		player_ref.close_inventory()
	# ✅ 新增：关闭背包，恢复交互
		GameState.game_paused = false
