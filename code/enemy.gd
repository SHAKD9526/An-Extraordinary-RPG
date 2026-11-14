extends CharacterBody2D

@export var hp:int = 120
@export var max_hp:int = 120
@export var speed:float = 120
@export var damage:int = 3
@export var attack_cd:float = 0.47
@export var detect_range:float = 450
@export var hysteresis_gap:float = 80
@export var stop_distance:float = 32.0
@export var knockback_force:float = 75
@export var knockback_duration:float = 0.25
@export var hurt_flash_time:float = 0.12 # 受伤闪白时长

# 两个重生锚点
@export var respawn_marker:Marker2D
@export var respawn_marker2:Marker2D
@export var respawn_time:float = 15.0
@export var max_spawn_count:int = 2
@export var spawn_chance:float = 0.75
# 标记：复制出来的小怪关闭复活
@export var can_respawn:bool = true
var hurt_cooldown: float = 0.2
var hurt_cd_timer: float = 0.0

var knockback_timer:float = 0.0
var knockback_dir:Vector2 = Vector2.ZERO
var attack_timer:float = 0.0
var player:Node2D = null
var is_chasing:bool = false
var is_dead:bool = false
var respawn_timer:float = 0.0
var hurt_tween:Tween = null # 保存闪白tween，防止叠加

func _ready():
	randomize()
	add_to_group("SlimeGroup")
	# 拿到场景里全部史莱姆，互相添加碰撞排除
	var all_slimes = get_tree().get_nodes_in_group("SlimeGroup")
	for slime in all_slimes:
		if slime != self and is_instance_valid(slime):
			add_collision_exception_with(slime)
			slime.add_collision_exception_with(self)

func _physics_process(delta):
	if GameState.game_paused:
		return

	if is_dead:
		if not can_respawn:
			return
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_try_respawn()
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("PlayerGroup")
		if player == null:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	if hurt_cd_timer > 0:
		hurt_cd_timer -= delta

	# 怪物被打的击退
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_dir * knockback_force * (knockback_timer / knockback_duration)
		move_and_slide()
		return

	if attack_timer > 0:
		attack_timer -= delta

	var dist = global_position.distance_to(player.global_position)

	if dist <= detect_range:
		is_chasing = true
	elif dist > detect_range + hysteresis_gap:
		is_chasing = false

	if not is_chasing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var move_dir = global_position.direction_to(player.global_position)
	if move_dir.length_squared() < 0.001:
		move_dir = Vector2.RIGHT

	if dist > stop_distance:
		velocity = move_dir * speed
	else:
		velocity = Vector2.ZERO

	# 攻击判定
	if $HurtArea.overlaps_body(player) and attack_timer <= 0:
		attack_timer = attack_cd
		if player.has_method("take_damage"):
			player.take_damage(damage, self)

	move_and_slide()

func take_damage(dmg:int, attacker:Node2D, no_knockback:bool = false, knockback_scale:float = 1.0):
	if attacker != null and attacker.is_in_group("SlimeGroup"):
		return
		
	hp -= dmg
	print (hp)
	hp = clamp(hp, 0, max_hp)

	if hurt_cd_timer <= 0:
		hurt_cd_timer = hurt_cooldown
		if hurt_tween != null and hurt_tween.is_valid():
			hurt_tween.kill()
		hurt_tween = create_tween()
		hurt_tween.tween_property($Sprite2D, "modulate", Color(1.765, 0.0, 0.0, 1.0), 0.0)
		SoundManager.play_smile()
		hurt_tween.tween_property($Sprite2D, "modulate", Color(1,1,1,1), hurt_flash_time)

	if not no_knockback:
		if attacker:
			knockback_dir = (global_position - attacker.global_position).normalized()
		else:
			knockback_dir = Vector2.RIGHT

		if knockback_dir.length_squared() < 0.001:
			knockback_dir = Vector2.RIGHT
		# 基础时长 × 武器倍率
		knockback_timer = knockback_duration * knockback_scale

	if hp <= 0 and not is_dead:
		is_dead = true
		GameState.gold += 5
		respawn_timer = respawn_time
		call_deferred("_set_dead_physics")




func _set_dead_physics():
	visible = false
	$CollisionShape2D.disabled = true
	$HurtArea.monitoring = false
	if hurt_tween != null and hurt_tween.is_valid():
		hurt_tween.kill()
		$Sprite2D.modulate = Color(1,1,1,1)

func _try_respawn():
	if randf() > spawn_chance:
		respawn_timer = respawn_time
		return

	var marker_list:Array[Marker2D] = []
	if respawn_marker != null and is_instance_valid(respawn_marker):
		marker_list.append(respawn_marker)
	if respawn_marker2 != null and is_instance_valid(respawn_marker2):
		marker_list.append(respawn_marker2)

	if marker_list.is_empty():
		print("⚠️ 没有有效的重生标记")
		return

	var spawn_num = randi_range(1, max_spawn_count + 1)
	for i in range(spawn_num):
		var idx = randi() % marker_list.size()
		var chosen_marker = marker_list[idx]
		var offset = Vector2(randf_range(-12,12), randf_range(-12,12))
		if i == 0:
			_reset_self()
			global_position = chosen_marker.global_position + offset
		else:
			var clone = duplicate()
			clone.can_respawn = false
			clone._reset_self()
			clone.global_position = chosen_marker.global_position + offset
			get_parent().add_child(clone)
			# 新生成的克隆，和所有老史莱姆互相排除碰撞
			var all_slimes = get_tree().get_nodes_in_group("SlimeGroup")
			for slime in all_slimes:
				if slime != clone and is_instance_valid(slime):
					clone.add_collision_exception_with(slime)
					slime.add_collision_exception_with(clone)


func _reset_self():
	is_dead = false
	hp = max_hp
	knockback_timer = 0
	attack_timer = 0
	is_chasing = false
	respawn_timer = 0
	visible = true
	$CollisionShape2D.disabled = false
	$HurtArea.monitoring = true
	$Sprite2D.modulate = Color(1,1,1,1) # 重生恢复颜色
