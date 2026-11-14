extends Node2D

@export var tree_template: Node2D = null
# 生成区域
@export var area_start: Vector2 = Vector2(-400, -300)
@export var area_end: Vector2 = Vector2(400, 300)

# ========== 宽高独立控制 ==========
@export var base_width: float = 4.3
@export var min_width_rand: float = 0.85
@export var max_width_rand: float = 1.15

@export var base_height: float = 8.4
@export var min_height_rand: float = 0.85
@export var max_height_rand: float = 1.15
# =================================

@export var enable_tilt: bool = false
@export var tilt_range: float = 6.0

@export var min_distance: float = 160.0
@export var auto_spawn_on_ready: bool = true
@export var show_area_gizmo: bool = true

var rng = RandomNumberGenerator.new()
var spawned_positions: PackedVector2Array = []

func _ready():
	rng.randomize()
	if tree_template:
		tree_template.visible = false
	if auto_spawn_on_ready:
		spawn_trees_poisson()

func spawn_trees_poisson():
	if not tree_template:
		push_error("请设置 TreeTemplate！")
		return
	# 清除旧树
	for child in get_children():
		if child != tree_template:
			child.queue_free()
	spawned_positions.clear()

	var rect = Rect2(area_start, area_end - area_start)
	var cell_size = min_distance / sqrt(2)
	var grid_w = int(rect.size.x / cell_size) + 1
	var grid_h = int(rect.size.y / cell_size) + 1

	# 初始化网格
	var grid: Array = []
	for y in range(grid_h):
		var row: Array = []
		for x in range(grid_w):
			row.append(-1)
		grid.append(row)

	var active_list: Array[Vector2] = []
	# 起始随机点
	var start_pos = Vector2(
		rng.randf_range(rect.position.x, rect.end.x),
		rng.randf_range(rect.position.y, rect.end.y)
	)
	_add_point(start_pos, rect, cell_size, grid, active_list)

	while active_list.size() > 0:
		var arr_len = active_list.size()
		var idx = rng.randi_range(0, arr_len - 1) # 重点：上限-1，杜绝越界
		var center = active_list[idx]
		var found = false

		# 围绕中心点尝试30个候选点
		for i in range(30):
			var angle = rng.randf() * PI * 2
			var dist = rng.randf_range(min_distance, min_distance * 2)
			var sample_pos = center + Vector2(cos(angle), sin(angle)) * dist
			if rect.has_point(sample_pos) and _is_valid(sample_pos, min_distance, grid, cell_size, spawned_positions):
				_add_point(sample_pos, rect, cell_size, grid, active_list)
				found = true
				break
		if not found:
			active_list.remove_at(idx)

	# 实例化树木
	for pos in spawned_positions:
		var tree = tree_template.duplicate()
		tree.visible = true
		tree.position = pos

		if enable_tilt:
			tree.rotation_degrees = rng.randf_range(-tilt_range, tilt_range)

		var final_w = base_width * rng.randf_range(min_width_rand, max_width_rand)
		var final_h = base_height * rng.randf_range(min_height_rand, max_height_rand)
		tree.scale = Vector2(final_w, final_h)

		var z_val = remap(tree.position.y, area_start.y, area_end.y, 4000, -4000)
		tree.z_index = int(z_val)
		add_child(tree)

func _add_point(pos:Vector2, rect:Rect2, cell_size:float, grid:Array, active:Array[Vector2]):
	spawned_positions.append(pos)
	active.append(pos)
	var gx = int((pos.x - rect.position.x) / cell_size)
	var gy = int((pos.y - rect.position.y) / cell_size)
	grid[gy][gx] = spawned_positions.size() - 1

func _is_valid(pos:Vector2, min_dist:float, grid:Array, cell_size:float, points:PackedVector2Array) -> bool:
	var gx = int((pos.x - area_start.x) / cell_size)
	var gy = int((pos.y - area_start.y) / cell_size)
	var check_range = 2
	for y in range(max(0, gy - check_range), min(grid.size(), gy + check_range + 1)):
		for x in range(max(0, gx - check_range), min(grid[0].size(), gx + check_range + 1)):
			var p_idx = grid[y][x]
			if p_idx != -1:
				if pos.distance_to(points[p_idx]) < min_dist:
					return false
	return true

func _draw():
	if not show_area_gizmo:
		return
	var rect = Rect2(area_start, area_end - area_start)
	draw_rect(rect, Color(0,1,0,0.3), false, 2)
