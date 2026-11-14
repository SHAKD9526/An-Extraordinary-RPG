extends CharacterBody2D

enum Mood { NEUTRAL, AMUSED, ANGRY, HURT, CALM }
var mood := Mood.NEUTRAL
var mercy := 0
var hp := 100
var max_hp := 100
var bullet_speed := 150.0
var fire_timer := 0.0
var spiral_ang := 0.0
var alive := true

@export var bullet_tex:Texture2D
@onready var soul:Node2D = $"../Soul"
@onready var bullet_layer:Node2D = $"../../BulletLayer"
@onready var battle:Node = get_parent().get_parent()

func _ready():
	add_to_group("Enemy")
	_start()

func _start():
	await battle.say("* 哼，又来一个送死的。")
	mood = Mood.NEUTRAL

func _physics_process(delta):
	if not alive: return
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = 1.1
		_fire()

func take_damage(dmg):
	if not alive: return
	hp -= dmg
	if hp <= 0:
		alive = false
		visible = false
		for b in bullet_layer.get_children():
			b.queue_free()
		return
	mood = Mood.ANGRY
	bullet_speed = min(bullet_speed + 10, 340)
	battle.say_async("* 疼！你真敢动手！")

func _fire():
	match mood:
		Mood.NEUTRAL: _ring(12)
		Mood.ANGRY: _spiral()
		Mood.AMUSED: _heart(8)
		Mood.HURT: _aim_fan()
		Mood.CALM: _ring(8)
	if mercy >= 2: _avoid()

func _ring(n):
	for i in n:
		var a = TAU * i / n
		_spawn(global_position, Vector2.from_angle(a))

func _spiral():
	spiral_ang += deg_to_rad(17)
	_spawn(global_position, Vector2.from_angle(spiral_ang))

func _heart(n):
	for i in n:
		var a = TAU*i/n + randf_range(-0.2,0.2)
		_spawn(global_position, Vector2.from_angle(a), bullet_speed*0.5)

func _aim_fan():
	if not is_instance_valid(soul): return
	var base = (soul.global_position - global_position).normalized()
	for i in 5:
		var off = deg_to_rad(lerp(-30.0,30.0,i/4.0))
		_spawn(global_position, base.rotated(off))

func _spawn(pos, dir, spd = bullet_speed):
	if bullet_layer == null: return
	var b := Area2D.new()
	b.set_script(load("res://bullet.gd"))
	b.add_to_group("enemy_bullet")
	var col := CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 6
	b.add_child(col)
	if bullet_tex:
		var s := Sprite2D.new()
		s.texture = bullet_tex
		s.scale = Vector2(0.5,0.5)
		b.add_child(s)
	b.global_position = pos
	b.vel = dir.normalized() * spd
	b.life = 6.0
	b.collision_layer = 0
	b.collision_mask = 0
	b.set_collision_layer_value(4, true)
	b.set_collision_mask_value(3, true)
	b.monitoring = true
	b.monitorable = true
	bullet_layer.add_child(b)

func _avoid():
	if not is_instance_valid(soul): return
	for b in bullet_layer.get_children():
		if b.is_in_group("enemy_bullet"):
			var away = (b.global_position - soul.global_position).normalized()
			b.vel += away * 60

func react_insult(line:String)->String:
	var l = line.to_lower()
	if "笑话" in l or "菜" in l:
		mood = Mood.AMUSED; mercy += 1; return "amused"
	elif "疼" in l or "哭" in l:
		mood = Mood.HURT; mercy += 1; return "hurt"
	else:
		mood = Mood.ANGRY; bullet_speed = min(bullet_speed+20,340); return "angry"

func run_chance()->float:
	return clamp(0.15 + mercy*0.2, 0.05, 0.95)
