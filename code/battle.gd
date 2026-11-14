extends Node2D

@onready var soul:CharacterBody2D = %Soul
@onready var enemy:CharacterBody2D = %Enemy
@onready var bullet_layer:Node2D = %BulletLayer
@onready var bullet_template:Area2D = %Bullet
@onready var dlg:Label = %DialogueLabel
@onready var menu:VBoxContainer = %Menu

var typing := false

func _ready():
	soul.hurt.connect(_on_soul_hurt)
	show_menu(["FIGHT","INSULT","USE ITEM","RUN"])

# ---------- 台词 ----------
func say(t:String):
	dlg.text = ""
	typing = true
	for i in t.length():
		dlg.text += t[i]
		await get_tree().create_timer(0.02).timeout
	typing = false
	await get_tree().create_timer(0.2).timeout

func say_async(t:String):
	say(t)

# ---------- 菜单 ----------
func clear_menu():
	for c in menu.get_children():
		c.queue_free()

func show_menu(opts:Array):
	clear_menu()
	for opt in opts:
		var b := Button.new()
		b.text = opt
		b.custom_minimum_size = Vector2(180,42)
		b.pressed.connect(_on_choice.bind(opt))
		menu.add_child(b)
	await get_tree().process_frame
	if menu.get_child_count()>0:
		menu.get_child(0).grab_focus()

func _on_choice(opt:String):
	match opt:
		"FIGHT":
			clear_menu()
			enemy.take_damage(10)
			await get_tree().create_timer(0.4).timeout
			show_menu(["FIGHT","INSULT","USE ITEM","RUN"])
		"INSULT":
			open_insult()
		"USE ITEM":
			clear_menu()
			await say("* 你翻了翻口袋，啥也没有。")
			show_menu(["FIGHT","INSULT","USE ITEM","RUN"])
		"RUN":
			clear_menu()
			if randf() < enemy.run_chance():
				await say("* 滚吧，懒得追。")
				get_tree().quit() # 先退出，后面换场景
			else:
				await say("* 想跑？没门！")
				enemy.mood = enemy.Mood.ANGRY
				show_menu(["FIGHT","INSULT","USE ITEM","RUN"])

func open_insult():
	clear_menu()
	var lines = ["你打的弹幕像打喷嚏。","骨头这么脆。","就这水平？","返回"]
	for l in lines:
		var b := Button.new()
		b.text = l
		b.custom_minimum_size = Vector2(240,38)
		b.pressed.connect(_on_insult.bind(l))
		menu.add_child(b)

func _on_insult(l:String):
	if l == "返回":
		show_menu(["FIGHT","INSULT","USE ITEM","RUN"])
		return
	clear_menu()
	var r = enemy.react_insult(l)
	if r == "amused":
		await say("* …哈，你嘴挺毒。")
	elif r == "hurt":
		await say("* 你这话……扎心。")
	else:
		await say("* 我生气了！！")
	show_menu(["FIGHT","INSULT","USE ITEM","RUN"])

# ---------- 受击 ----------
func _on_soul_hurt(dmg):
	await say("* 呜…被擦到了。")
