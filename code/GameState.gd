extends Node
enum EndingState {NONE, SINGLE_ESCAPE, COMPANION_ESCAPE}
# 剧情标记
signal hp_changed(current:int, max_value:int)
signal mp_changed(current:int, max_value:int)
signal play_time_changed(new_time: float)
var day_night_t: float = 0.0
var play_time: float = 0.0
signal die_changed(new_count: int)
signal gold_changed(new_gold: int)
var game_paused:bool = false
var frisk_obtained:bool = false
#var GameState:Node = null
var gold: int = 95 # 初始金币，你自己改
var story_progress:int = 0
var current_ending:EndingState = EndingState.NONE
var has_companion:bool = false
var read_soldier_diary:bool = false
var has_blood_knife_flag:bool = false
# 角色持久数据
var hp:int = 100
var max_hp:int = 100
var mp:int = 50
var mag:int = 12
var max_mp:int = 50
var equipped_weapon:String = ""
var die:int = 0

# ✅ 全局唯一武器表，全部统一在这里维护！字段 dmg、cd，和Player读取一致
@export var weapon_stats:Dictionary = {
	"": { "dmg":0.1, "cd":0.15 },
	"水果刀": { "dmg":4, "cd":0.30 },
	"血色小刀": { "dmg":12, "cd":1.1 },
	"手枪": { "dmg":5, "cd":0.1 },
	"武士刀": {"dmg":5, "cd":0.35}
}

# 背包唯一数据源
var inventory:Array[Dictionary] = []
var is_init:bool = false

signal inventory_changed

func _ready():
	if not is_init:
		# 开局默认背包
		inventory = [
			{"name":"面包", "count":5},
			{"name":"水果刀", "count":1},
		]
		#global_add_item("手枪", 1)
		#global_add_item("手枪子弹", 100)
		#global_add_item("武士刀",1)
		# ==========开局自动装备水果刀==========
		equipped_weapon = "水果刀" # 补上这句，开局自动装备水果刀
		is_init = true
		print("🎒GameState初始化完成，初始背包：", inventory)
		print("🗡️开局自动装备：", equipped_weapon)


# 添加物品，同名叠加
func global_add_item(item_name:String, count:int):
	if count <= 0:
		return
	for item in inventory:
		if item["name"] == item_name:
			item["count"] += count
			emit_signal("inventory_changed")
			return
	inventory.append({"name":item_name, "count":count})
	emit_signal("inventory_changed")
	print("📦获得物品 %s ×%d" % [item_name, count])

# 判断是否拥有道具
func global_has_item(item_name:String) -> bool:
	for item in inventory:
		if item["name"] == item_name and item["count"] > 0:
			return true
	return false

# 消耗道具，返回是否消耗成功
func global_consume_item(item_name:String, count:int = 1) -> bool:
	if count <= 0:
		return false
	for i in range(inventory.size()):
		var it = inventory[i]
		if it["name"] == item_name:
			it["count"] -= count
			if it["count"] <= 0:
				inventory.remove_at(i)
			emit_signal("inventory_changed")
			return true
	return false

func clear_test_data():
	play_time = 0.0
	die = 0
	inventory.clear()
	story_progress = 0
	hp = max_hp
	mp = max_mp
	current_ending = EndingState.NONE
	has_companion = false
	read_soldier_diary = false
	has_blood_knife_flag = false
	equipped_weapon = ""
	is_init = false

func heal(amount:int):
	hp = min(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("gold_changed", gold)
		return true
	return false

# 获取物品数量，没有就返回0
func global_get_item_count(item_name:String) -> int:
	for item in inventory:
		if item["name"] == item_name:
			return item["count"]
	return 0

func add_die():
	die += 1
	emit_signal("die_changed", die)

func format_play_time(sec: float) -> String:
	var total = int(sec)
	var h = total / 3600
	var m = (total % 3600) / 60
	var s = total % 60
	return "%02d:%02d:%02d" % [h, m, s]

func _process(delta: float):
	if not game_paused:
		play_time += delta
		emit_signal("play_time_changed", play_time)
