extends CharacterBody2D
var is_revive_invincible: bool = false
var revive_invincible_timer: float = 0.0
@export var revive_invincible_time: float = 2.0
@export var cam_ref: Camera2D = null
#I made this game using a Thinkpad X250
# 剧情进度移至GameState，此处不再保存持久数据
# 先拿到耐力条引用，和hp_ui_ref一样的方式
var is_dodging: bool = false
var dodge_speed: float = 680.0
var dodge_duration: float = 0.27
var dodge_cooldown: float = 0.5
var dodge_timer: float = 0.0
var dodge_cd_timer: float = 0.5
var dodge_dir: Vector2 = Vector2.RIGHT
#++++++++++++++
var pause_panel:Control = null
@export var pause_scene:PackedScene
var inventory_open:bool = false
@export var sprint_ui_ref:Node
@export var Frisk:float = 20
@export var Kris:float = 20
@export var tex_gun_left: Texture2D
@export var tex_gun_right: Texture2D
var tex_gun_up: Texture2D = preload("res://fuirlsey_2_gun.png")
var tex_gun_down: Texture2D = preload("res://fuirlsey_1_gun.png")
@export var tex_down: Texture2D
@export var tex_up: Texture2D
@export var tex_left: Texture2D
@export var tex_right: Texture2D
#=======================================
# 角色朝向（默认向右）
var face_dir: Vector2 = Vector2.RIGHT
@export var inventory_scene:PackedScene
@export var hp_ui_ref:Node
var GameState:Node = null
var in_dialogue:bool = false
var inventory_instance:ColorRect = null
@export var can_move:bool = true
@export var speed:float = 360.0
@export var run_speed:float = 580.0 # 新增奔跑速度
# ============耐力参数============
@export var max_run_duration:float = 25.0        # 满状态最大可连续奔跑时长
@export var spurt_cooldown:float = 3.5           # 耗尽后的强制喘息时间
@export var sprint_recover_rate:float = 1.0      # 每秒恢复的疾跑时间(不要设太高)
var exhaust_cd:float = 0.0
var available_sprint:float = 25.0               # 当前剩余可奔跑时间
var is_exhausted:bool = false
# =================================
# hp/mp/max_hp/max_mp 移至GameState，本地仅做缓存
var hp:int = 100
var max_hp:int = 100
var mp:int = 50
var max_mp:int = 50
########
var hitstop_cooldown: float = 0.0
@export var hitstop_duration: float = 0.05
@export var hitstop_scale: float = 0.24
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
@export var combo_window: float = 2.0 # 2秒连击窗口期
@export var max_combo: float = 1.85
# 翻滚后连击窗口：翻滚结束可以快速打2刀
var dodge_combo_remain: int = 0
var dodge_combo_window: float = 0.35
var dodge_combo_timer: float = 0.0
# 翻滚增伤层数：2层，两刀都吃1.7倍
var dodge_buff_stack: int = 0


const SLASH_TEXTURE:Texture2D = preload("res://s_3.png")
@export var attack_cd:float = 0.75
@export var attack_stun:float = 0.3 #挥刀硬直时间
@export var attack_range:float = 72.0
@export var attack_damage:int = 15
# 你被击退参数
@export var knockback_force:float = 1000
@export var knockback_duration:float = 0.25

# ========== 手枪新增配置 ==========
@export var pistol_max_range:float = 350.0
@export var pistol_fire_cd:float = 0.1
@export_flags_2d_physics var ray_mask:int = 0
var pistol_cd_timer:float = 0.0
# =================================

# has_companion、equipped_weapon、inventory 移到GameState，本地做缓存
var equipped_weapon:String = ""

# 死亡全屏画面
@export var death_texture:Texture2D
@export var death_display_time:float = 5.0

var death_sprite:Sprite2D = null
var is_dead:bool = false
var knockback_timer:float = 0.0
var knockback_dir:Vector2 = Vector2.ZERO
var attack_cooldown:float = 0.0
var stun_timer:float = 0.0
var mouse_was_down:bool = false

# 武器配置，直接存该武器对应的属性

var dodge_buff_timer: float = 0.0
@export var dodge_buff_duration: float = 0.85
@export var dodge_buff_multiplier: float = 1.7

# 武士刀 连击加速层
@export var katana_max_stack: int = 60        # 最多叠几层
@export var katana_base_cd: float = 0.26
@export var katana_min_cd: float = 0.04     # 叠满之后最低冷却
@export var katana_base_dmg: int = 8
@export var katana_dmg_falloff: float = 0.80 # 每一层伤害乘这个系数
@export var katana_reset_time: float = 1.0  # 停多久清零
@export var katana_no_knockback: bool = true # 关闭击退
@export var katana_stun: float = 0.3
var knockback_scale:float

var katana_stack: int = 0
var katana_reset_timer: float = 0.0


func equip_weapon(weapon_name:String):
	#print("👉 equip_weapon 收到名称：【", weapon_name, "】")
	var stat = GameState.weapon_stats.get(weapon_name, GameState.weapon_stats[""])
	attack_damage = stat["dmg"]
	attack_cd = stat["cd"]
	equipped_weapon = weapon_name
	GameState.equipped_weapon = weapon_name
	#print("✅ 装备成功：", weapon_name, " 伤害：", attack_damage, " cd:", attack_cd)
	# 新增校验打印，确认赋值之后变量值
	#print("DEBUG校验：本地attack_damage=", attack_damage, " attack_cd=", attack_cd)


func _ready():
	$Camera2D.make_current()
	GameState = get_tree().root.get_node_or_null("GameState")
	if GameState == null:
		push_error("致命错误：找不到GameState")
		return
	
	hp = GameState.hp
	max_hp = GameState.max_hp
	mp = GameState.mp
	max_mp = GameState.max_mp
	equipped_weapon = GameState.equipped_weapon
	var stat = GameState.weapon_stats.get(equipped_weapon, GameState.weapon_stats[""])
	attack_damage = stat["dmg"]
	attack_cd = stat["cd"]
	if $Sprite2D:
		match face_dir:
			Vector2.RIGHT: $Sprite2D.texture = tex_right
			Vector2.LEFT: $Sprite2D.texture = tex_left
			Vector2.DOWN: $Sprite2D.texture = tex_down
			Vector2.UP: $Sprite2D.texture = tex_up


func _input(event: InputEvent):
	#print("收到输入事件：", event)
	if GameState.game_paused or is_dead or in_dialogue:
		return
	if inventory_instance != null and is_instance_valid(inventory_instance):
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			#print("✅ 右键按下，准备翻滚")
			if dodge_cd_timer > 0 or knockback_timer > 0 or stun_timer > 0:
				print("❌ 翻滚被阻挡：冷却/击退/硬直")
				return
			# 消耗5点耐力
			if available_sprint < 3:
				#print("❌ 耐力不足，无法翻滚")
				return
			available_sprint -= 3
			dodge_dir = face_dir
			start_dodge()
			#print("🚀 执行翻滚，消耗3耐力")





func start_dodge():
	is_dodging = true
	dodge_timer = dodge_duration
	dodge_cd_timer = dodge_cooldown
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2,2,2,1), 0.05)
	tween.tween_property(self, "modulate", Color(1,1,1,1), 0.13)
	SoundManager.play_dodge()


func _physics_process(delta:float) -> void:
	if GameState.game_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# ========= 翻滚优先执行 =========
	if is_dodging:
		dodge_timer -= delta
		velocity = dodge_dir * dodge_speed
		move_and_slide()
		if dodge_timer <= 0:
			is_dodging = false
			dodge_buff_timer = dodge_buff_duration  # 翻滚结束，给0.25s增伤buff窗口
			dodge_buff_stack = 2                    # 2层增伤，两刀都1.7倍
			dodge_combo_remain = 2
			dodge_combo_timer = dodge_combo_window
		mouse_was_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	# =================================
	# 翻滚连击窗口倒计时
	if dodge_combo_remain > 0:
		dodge_combo_timer -= delta
		if dodge_combo_timer <= 0:
			dodge_combo_remain = 0

	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_dir * knockback_force * (knockback_timer / knockback_duration) * -1
		move_and_slide()
		mouse_was_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		return
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if stun_timer > 0:
		stun_timer -= delta
	if stun_timer > 0:
		velocity = Vector2.ZERO
		move_and_slide()
		mouse_was_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		return

	var lock_bag = (inventory_instance != null and is_instance_valid(inventory_instance))
	var lock_dialog_flag = in_dialogue
	var lock_old = not can_move
	var is_dialog_mode = lock_dialog_flag or lock_old

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 背包打开：完全禁止移动
	if lock_bag:
		input_dir = Vector2.ZERO

	var holding_run:bool = Input.is_action_pressed("shift_run") and input_dir.length() > 0
	if exhaust_cd > 0:
		exhaust_cd -= delta
	if holding_run and exhaust_cd <= 0 and available_sprint > 0:
		available_sprint -= delta
		if available_sprint <= 0:
			available_sprint = 0
			exhaust_cd = spurt_cooldown
			is_exhausted = true
	else:
		if exhaust_cd <= 0:
			available_sprint += sprint_recover_rate * delta
			available_sprint = clamp(available_sprint, 0.0, max_run_duration)
			is_exhausted = available_sprint <= 0
	var can_sprint:bool = exhaust_cd <= 0 and available_sprint > 0

	var actual_speed:float
	if is_dialog_mode:
		actual_speed = 40.0
	elif can_sprint and holding_run:
		actual_speed = run_speed
	else:
		actual_speed = speed

	velocity = input_dir * actual_speed
	move_and_slide()

	if $Sprite2D:
		if input_dir.length() > 0:
			if abs(input_dir.x) > abs(input_dir.y):
				face_dir = Vector2.RIGHT if input_dir.x > 0 else Vector2.LEFT
			else:
				face_dir = Vector2.DOWN if input_dir.y > 0 else Vector2.UP
		match face_dir:
			Vector2.RIGHT:
				$Sprite2D.texture = tex_gun_right if equipped_weapon == "手枪" else tex_right
			Vector2.LEFT:
				$Sprite2D.texture = tex_gun_left if equipped_weapon == "手枪" else tex_left
			Vector2.DOWN:
				$Sprite2D.texture = tex_gun_down if equipped_weapon == "手枪" else tex_down
			Vector2.UP:
				$Sprite2D.texture = tex_gun_up if equipped_weapon == "手枪" else tex_up


	# ✅ 对话期间依然禁止攻击/射击，只允许缓慢移动
	var mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_down and not mouse_was_down and not is_dialog_mode and not lock_bag and stun_timer <= 0 and knockback_timer <= 0:
		if equipped_weapon == "手枪":
			shoot_pistol()
		else:
			if attack_cooldown <= 0.0:
				do_attack()
	mouse_was_down = mouse_down
	# 更新耐力UI
	if sprint_ui_ref != null and sprint_ui_ref.has_method("set_sprint"):
		sprint_ui_ref.set_sprint(available_sprint, max_run_duration, is_exhausted)


# 手枪射击函数
func shoot_pistol():
	if pistol_cd_timer > 0:
		return
	# 消耗子弹
	if not GameState.global_consume_item("手枪子弹", 1):
		print("❌ 没有手枪子弹！")
		return
	pistol_cd_timer = pistol_fire_cd

	var muzzle_pos = global_position + Vector2(0, -12)
	var mouse_global = get_global_mouse_position()
	var dir = (mouse_global - muzzle_pos).normalized()
	var end_pos = muzzle_pos + dir * pistol_max_range

	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(muzzle_pos, end_pos, ray_mask, [self])
	var hit_result = space.intersect_ray(query)

	if hit_result:
		var collider = hit_result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(5, self)
			print("✅ 手枪命中敌人")
		else:
			print("🧱 击中障碍物")
	else:
		print("💨 超出射程，脱靶")

# 背包输入处理，放在 _process
func _process(delta:float):
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_multiplier = 1.0 # 超时重置倍率

	if dodge_buff_timer > 0:
		dodge_buff_timer -= delta

	if GameState.game_paused:
		return

	equipped_weapon = GameState.equipped_weapon
	if is_dead:
		return

	# 武士刀层数倒计时
	if katana_stack > 0:
		katana_reset_timer -= delta
		if katana_reset_timer <= 0:
			katana_stack = 0
			katana_reset_timer = 0

	# 手枪冷却计时
	if pistol_cd_timer > 0:
		pistol_cd_timer -= delta
	# 翻滚冷却计时
	if dodge_cd_timer > 0:
		dodge_cd_timer -= delta

	# 复活无敌计时+闪烁
	if is_revive_invincible:
		revive_invincible_timer -= delta
		var alpha: float
		if fmod(revive_invincible_timer * 10, 1.0) > 0.5:
			alpha = 0.3
		else:
			alpha = 1.0
		$Sprite2D.modulate = Color(1,1,1, alpha)
		if revive_invincible_timer <= 0:
			is_revive_invincible = false
			$Sprite2D.modulate = Color(1,1,1,1)

	# ESC 暂停开关
	if Input.is_action_just_pressed("ui_cancel") and not is_dead and not in_dialogue and not is_instance_valid(inventory_instance):
		if pause_panel == null or not is_instance_valid(pause_panel):
			pause_panel = pause_scene.instantiate()
			var canvas = get_tree().root.get_node_or_null("CanvasLayer")
			if canvas == null:
				canvas = CanvasLayer.new()
				canvas.name = "CanvasLayer"
				get_tree().root.add_child(canvas)
			canvas.add_child(pause_panel)

		if pause_panel.visible:
			pause_panel.close()
		else:
			pause_panel.open()

	# 打开背包
	if Input.is_action_just_pressed("ui_inventory"):
		toggle_inventory()

	if hitstop_cooldown > 0:
		hitstop_cooldown -= delta




func toggle_inventory():
	print("👉 toggle_inventory 被执行")
	if inventory_instance == null or not is_instance_valid(inventory_instance):
		if inventory_scene != null:
			print("实例化背包")
			inventory_instance = inventory_scene.instantiate()
			inventory_instance.player_ref = self
			var canvas_layer = get_tree().root.get_node_or_null("CanvasLayer")
			if canvas_layer == null:
				canvas_layer = CanvasLayer.new()
				canvas_layer.name = "CanvasLayer"
				get_tree().root.add_child(canvas_layer)
			canvas_layer.add_child(inventory_instance)
			inventory_instance.refresh_items()
			inventory_instance.is_open = true
		else:
			print("⚠️ inventory_scene为空")
	else:
		print("调用close_inventory关闭背包")
		close_inventory()


func close_inventory():
	if inventory_instance != null and is_instance_valid(inventory_instance):
		inventory_instance.queue_free()
	inventory_instance = null


func do_attack():
	if is_exhausted:
		return

	# ========== 武士刀分支 ==========
	var is_katana = equipped_weapon == "武士刀"
	var final_dmg: int
	var use_stun: float
	var use_knockback: bool = true
	var knockback_scale:float

	if is_katana:
		var t = float(katana_stack) / katana_max_stack
		attack_cooldown = lerp(katana_base_cd, katana_min_cd, t)
		final_dmg = round( max(2.0, katana_base_dmg * lerp(1.0, katana_dmg_falloff, t)) )
		use_stun = katana_stun
		use_knockback = not katana_no_knockback
		knockback_scale = 0.6

		# 空挥直接叠层、重置倒计时
		katana_stack = min(katana_stack + 1, katana_max_stack)
		katana_reset_timer = katana_reset_time
	else:
		# 原有普通武器逻辑，完全不动
		if dodge_combo_remain > 0:
			dodge_combo_remain -= 1
		else:
			attack_cooldown = attack_cd
		final_dmg = attack_damage
		use_stun = attack_stun

		match equipped_weapon:
			"水果刀":
				knockback_scale = 0.7
			"血色小刀":
				knockback_scale = 2.0
			"手枪":
				knockback_scale = 0.07
			_:
				knockback_scale = 1.0

	SoundManager.play_slash()
	available_sprint = clamp(available_sprint - 0.75, 0.0, max_run_duration)
	stun_timer = use_stun #开启硬直
	# 生成斩击视觉特效
	var slash = Sprite2D.new()
	slash.texture = SLASH_TEXTURE
	slash.scale = Vector2(3.6,3.6)

	# ========== 空挥轻震 ==========
	var cam = get_node_or_null("Camera2D")
	if cam != null and cam.has_method("swing_miss"):
		cam.swing_miss(face_dir)

	var spawn_pos = global_position
	# 根据face_dir决定斩击偏移
	match face_dir:
		Vector2.RIGHT:
			slash.rotation = 0.0
			spawn_pos.x += 46
		Vector2.LEFT:
			slash.rotation = PI
			spawn_pos.x -= 46
		Vector2.DOWN:
			slash.rotation = PI / 2
			spawn_pos.y += 70
			spawn_pos.x += -0
		Vector2.UP:
			slash.rotation = -PI / 2
			spawn_pos.y -= 66
			spawn_pos.x += -0
	slash.global_position = spawn_pos
	get_parent().add_child(slash)

	var hit_area = Area2D.new()
	var shape_2d = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(attack_range, 52)
	shape_2d.shape = rect_shape
	hit_area.add_child(shape_2d)
	hit_area.global_position = spawn_pos
	get_parent().add_child(hit_area)
	hit_area.monitoring = true
	hit_area.monitorable = false

	# ========== 翻滚结束增伤buff计算 =====
	if not is_katana and dodge_buff_timer > 0 and dodge_buff_stack > 0:
		final_dmg *= dodge_buff_multiplier
		dodge_buff_stack -= 1

	hit_area.set_meta("hit_list", [])
	hit_area.set_meta("dmg", final_dmg)
	hit_area.set_meta("attacker", self)
	hit_area.set_meta("no_knockback", not use_knockback)
	hit_area.set_meta("knockback_scale", knockback_scale)
	hit_area.body_entered.connect(_hit_callback.bind(hit_area))
	await get_tree().create_timer(0.11).timeout
	slash.queue_free()
	hit_area.queue_free()






func _hit_callback(body:Node2D, hit_area:Area2D):
	if not is_instance_valid(body) or not is_instance_valid(hit_area):
		return
	var hit_list:Array = hit_area.get_meta("hit_list")
	var dmg:int = hit_area.get_meta("dmg")
	var attacker:Node2D = hit_area.get_meta("attacker")
	# 读取击退倍率，不存在meta默认1.0
	var knockback_scale:float = hit_area.get_meta("knockback_scale", 1.0)

	if body.is_in_group("Enemy") and not body in hit_list:
		hit_list.append(body)
		hit_area.set_meta("hit_list", hit_list)
		# no_knockback固定false，全部允许击退
		body.take_damage(dmg, attacker, false, knockback_scale)

		# ===== 连击更新 =====
		combo_multiplier *= 1.1
		combo_multiplier = min(combo_multiplier, max_combo)
		combo_timer = combo_window # 刷新3秒连击窗口

		var cam = get_node_or_null("Camera2D")
		if cam != null and cam.has_method("hit_enemy"):
			cam.hit_enemy(face_dir, combo_multiplier)

		trigger_hitstop()


func take_damage(dmg:int, attacker:Node2D):
	if is_dead or is_dodging or is_revive_invincible:
		return
	GameState.hp -= dmg
	GameState.hp = clamp(GameState.hp, 0, GameState.max_hp)
	hp = GameState.hp
	print("受到伤害！剩余生命：", GameState.hp)
	# 改用绑定引用，不再get_node查找
	if hp_ui_ref != null:
		hp_ui_ref.set_hp(GameState.hp, GameState.max_hp)
	else:
		print("hp_ui_ref为空，未在编辑器拖入节点")

	knockback_dir = (global_position - attacker.global_position).normalized()
	if knockback_dir.length_squared() < 0.001:
		knockback_dir = Vector2.RIGHT
	knockback_timer = knockback_duration

	# ========= 新增：玩家受伤，触发震屏+镜头收缩 =========
	if cam_ref != null:
		cam_ref.hurt_player(knockback_dir)

	if GameState.hp <= 0:
		die()




func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	stun_timer = 0.0
	attack_cooldown = 0.0

	# ===== 死亡惩罚：扣除10金币，用自带spend_gold，自动发gold_changed信号 =====
	var ok = GameState.spend_gold(10)
	GameState.die += 1
	if ok:
		print("💀 死亡，扣除10金币,die:",GameState.die)
	else:
		print("💀 死亡，金币不足，不扣",GameState.die)

	if $Sprite2D:
		$Sprite2D.visible = false
	death_sprite = Sprite2D.new()
	death_sprite.texture = death_texture
	death_sprite.name = "DeathScreen"
	death_sprite.z_index = 4000
	get_parent().add_child(death_sprite)
	_adjust_death_sprite_to_fullscreen()
	
	if hp_ui_ref != null:
		hp_ui_ref.visible = false

	await get_tree().create_timer(death_display_time).timeout
	respawn()



func _adjust_death_sprite_to_fullscreen():
	if death_sprite == null or not is_instance_valid(death_sprite):
		return
	if death_sprite.texture == null:
		push_warning("死亡贴图为空，请把死亡图片拖到 Player 的 death_texture 槽位。")
		return
	var camera = $Camera2D
	if camera == null:
		return
	# 用 Camera2D 的可见范围计算，而不是 viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom
	var screen_size = viewport_size / zoom
	var tex_size = death_sprite.texture.get_size()
	if tex_size.x == 0 or tex_size.y == 0:
		return
	var scale_x = screen_size.x / tex_size.x
	var scale_y = screen_size.y / tex_size.y
	var scale = max(scale_x, scale_y)
	death_sprite.scale = Vector2(scale, scale)
	death_sprite.global_position = camera.global_position

func respawn():
	is_dead = false
	GameState.hp = GameState.max_hp
	hp = GameState.hp
	# 复活重置【新间歇耐力变量】
	is_exhausted = false
	available_sprint = max_run_duration
	exhaust_cd = 0.0
	# 重置战斗计时器
	knockback_timer = 0.0
	stun_timer = 0.0
	attack_cooldown = 0.0
	pistol_cd_timer = 0.0
	# 武士刀层数复活清零
	katana_stack = 0
	katana_reset_timer = 0.0
	velocity = Vector2.ZERO
	if $Sprite2D.visible == false:
		$Sprite2D.visible = true
	if death_sprite != null and is_instance_valid(death_sprite):
		death_sprite.queue_free()
		death_sprite = null
	#复活时如果背包还开着，强制关闭
	close_inventory()

	# 新增：复活打开血条，并刷新满血贴图
	if hp_ui_ref != null:
		hp_ui_ref.visible = true
		hp_ui_ref.set_hp(GameState.hp, GameState.max_hp)

	# ========== 复活2秒无敌 ==========
	is_revive_invincible = true
	revive_invincible_timer = 2.0

func trigger_hitstop():
	if hitstop_cooldown > 0:
		return
	Engine.time_scale = hitstop_scale
	hitstop_cooldown = 0.15
	# ignore_time_scale=true 计时器不受慢动作影响，时间到立刻恢复
	await get_tree().create_timer(hitstop_duration, true).timeout
	Engine.time_scale = 1.0




func _on_sense_area_area_entered(area: Area2D) -> void:
	pass

func _on_sense_area_area_exited(area: Area2D) -> void:
	pass

#I like 我的世界木鱼
