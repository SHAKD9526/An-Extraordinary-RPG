extends Node2D

@export var tree_template: Node2D = null
@export var spawn_count: int = 500

# 生成区域
@export var area_start: Vector2 = Vector2(-400, -300)
@export var area_end: Vector2 = Vector2(400, 300)

# ========== 宽高独立控制 ==========
@export var base_width: float = 4.0
@export var min_width_rand: float = 0.85
@export var max_width_rand: float = 1.15

@export var base_height: float = 8.0
@export var min_height_rand: float = 0.85
@export var max_height_rand: float = 1.15
# =================================

@export var enable_tilt: bool = false
@export var tilt_range: float = 6.0

@export var min_distance: float = 160.0  # 调大这个，树之间隔更远
@export var max_try: int = 800  # 最多重试次数，防止死循环
@export var auto_spawn_on_ready: bool = true
@export var show_area_gizmo: bool = true

var rng = RandomNumberGenerator.new()
var spawned_positions: PackedVector2Array = []

func _ready():
	rng.randomize()
	if tree_template:
		tree_template.visible = false
	if auto_spawn_on_ready:
		spawn_trees()

func spawn_trees():
	if not tree_template:
		push_error("请设置 TreeTemplate！")
		return

	for child in get_children():
		if child != tree_template:
			child.queue_free()
	spawned_positions.clear()

	var current_count = 0
	var try_times = 0
	
	while current_count < spawn_count and try_times < max_try:
		var pos = get_random_pos_in_area()
		var ok = true
		for p in spawned_positions:
			if pos.distance_to(p) < min_distance:
				ok = false
				break
		if ok:
			var tree = tree_template.duplicate()
			tree.visible = true
			tree.position = pos

			if enable_tilt:
				tree.rotation_degrees = rng.randf_range(-tilt_range, tilt_range)

			var final_w = base_width * rng.randf_range(min_width_rand, max_width_rand)
			var final_h = base_height * rng.randf_range(min_height_rand, max_height_rand)
			tree.scale = Vector2(final_w, final_h)

			tree.z_index = -int(tree.position.y)
			add_child(tree)
			spawned_positions.append(pos)
			current_count += 1
		try_times += 1

func get_random_pos_in_area() -> Vector2:
	var x = rng.randf_range(area_start.x, area_end.x)
	var y = rng.randf_range(area_start.y, area_end.y)
	return Vector2(x, y)

func _draw():
	if not show_area_gizmo:
		return
	var rect = Rect2(area_start, area_end - area_start)
	draw_rect(rect, Color(0,1,0,0.3), false, 2)
