extends Node2D
class_name GridManager

# --- exported settings --------------------------------------------------
@export var cell_size : Vector2i = Vector2i(16, 16)
@export var collision_container_path: NodePath
@export var interactable_tilemap_path: NodePath

# --- grid objects -------------------------------------------------------
var astar_grid : AStarGrid2D = AStarGrid2D.new()
var grid_size  : Vector2i
var last_origin       # will hold the top-left cell of the last built region

# --- signals ------------------------------------------------------------
signal grid_initialized

# helper: recursively collect all TileMapLayer children under the collision container
func _collect_tilemaps(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is TileMapLayer:
			out.append(child)
		elif child is Node:
			_collect_tilemaps(child, out)

func _get_collision_tilemaps() -> Array:
	var results := []
	var root = get_node_or_null(collision_container_path)
	if root:
		_collect_tilemaps(root, results)
	return results

func _ready() -> void:
	get_tree().root.size_changed.connect(initialize_grid)
	set_process(true)
	initialize_grid()
	queue_redraw()
	emit_signal("grid_initialized")

func _process(_delta: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var vsz = get_viewport_rect().size
	var world_size = vsz * cam.zoom
	var origin_world = cam.global_position - world_size * 0.5
	var origin_cell = Vector2i(
		int(floor(origin_world.x / cell_size.x)),
		int(floor(origin_world.y / cell_size.y))
	)
	if last_origin == null or origin_cell != last_origin:
		initialize_grid()
		last_origin = origin_cell

func initialize_grid() -> void:
	# reset & define region
	astar_grid.clear()
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var vsz = get_viewport_rect().size
	var world_size = vsz * cam.zoom
	var gx = int(ceil(world_size.x / cell_size.x)) + 1
	var gy = int(ceil(world_size.y / cell_size.y)) + 1
	grid_size = Vector2i(gx, gy)

	var origin_world = cam.global_position - world_size * 0.5
	var origin_cell = Vector2i(
		int(floor(origin_world.x / cell_size.x)),
		int(floor(origin_world.y / cell_size.y))
	)

	astar_grid.region        = Rect2i(origin_cell.x, origin_cell.y, grid_size.x, grid_size.y)
	astar_grid.cell_size     = cell_size
	astar_grid.offset        = cell_size * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

	# 1) mark solid tiles from your TileMapLayer collisions
	for tm in _get_collision_tilemaps():
		for lx in range(grid_size.x):
			for ly in range(grid_size.y):
				var cell = Vector2i(origin_cell.x + lx, origin_cell.y + ly)
				var data: TileData = tm.get_cell_tile_data(cell)
				if data and data.get_collision_polygons_count(0) > 0:
					astar_grid.set_point_solid(cell, true)

	# 2) mark solid cells where physics‐layer-0 bodies exist
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1 << 0
	for lx in range(grid_size.x):
		for ly in range(grid_size.y):
			var cell = Vector2i(origin_cell.x + lx, origin_cell.y + ly)
			var center = Vector2(
				cell.x * cell_size.x + cell_size.x * 0.5,
				cell.y * cell_size.y + cell_size.y * 0.5
			)
			query.position = center
			if space.intersect_point(query).size() > 0:
				astar_grid.set_point_solid(cell, true)

	queue_redraw()
	emit_signal("grid_initialized")

func schedule_respawn(cell: Vector2i, source_id: int, atlas_coords: Vector2i, delay: float) -> void:
	var timer = get_tree().create_timer(delay)
	var cb = Callable(self, "_on_respawn_timeout").bind(cell, source_id, atlas_coords)
	timer.connect("timeout", cb)

func _on_respawn_timeout(cell: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	var tm = get_node(interactable_tilemap_path) as TileMapLayer
	tm.set_cell(cell, source_id, atlas_coords)
	tm.update_internals()
	if astar_grid.is_in_boundsv(cell):
		astar_grid.set_point_solid(cell, true)
	emit_signal("grid_initialized")
