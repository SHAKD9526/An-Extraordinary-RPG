extends CharacterBody2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var patrol_radius: float = 180.0
@export var detect_range: float = 85.0
@export var move_speed: float = 40.0
@export var wait_time: float = 2.8

var player: Node2D = null
var is_watching_player: bool = false
var wait_timer: float = 0.0

func _ready():
	nav_agent.target_desired_distance = 6.0
	nav_agent.path_desired_distance = 5.0
	visible = false
	collision_shape.disabled = true
	set_physics_process(false)

func _physics_process(delta):
	#print("昼夜t值：", GameState.day_night_t)
	# 读取昼夜，白天休眠
	if GameState.day_night_t < 0.45:
		visible = false
		collision_shape.disabled = true
		set_physics_process(false)
		velocity = Vector2.ZERO
		return

	# 夜晚激活
	visible = true
	collision_shape.disabled = true
	set_physics_process(true)

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("PlayerGroup")
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player < detect_range:
		is_watching_player = true
		var dir_to_player = global_position.direction_to(player.global_position)
		rotation = dir_to_player.angle()
		velocity = Vector2.ZERO
	else:
		is_watching_player = false
		if nav_agent.is_navigation_finished():
			wait_timer -= delta
			if wait_timer <= 0:
				pick_new_patrol_point()
				wait_timer = wait_time
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_pos)
			velocity = dir * move_speed
	move_and_slide()

func pick_new_patrol_point():
	var random_offset = Vector2(randf_range(-patrol_radius, patrol_radius), randf_range(-patrol_radius, patrol_radius))
	var raw_target = global_position + random_offset
	# 替换原来的snap，在导航地图上找最近可行点
	var nav_map = get_world_2d().get_navigation_map()
	var valid_point = NavigationServer2D.map_get_closest_point(nav_map, raw_target)
	nav_agent.target_position = valid_point
