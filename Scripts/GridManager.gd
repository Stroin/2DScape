# res://Scripts/GridManager.gd

extends Node2D
class_name GridManager

# --- exported settings --------------------------------------------------
@export var cell_size : Vector2i = Vector2i(64, 64)

# --- grid objects -------------------------------------------------------
var astar_grid : AStarGrid2D = AStarGrid2D.new()
var grid_size  : Vector2i

# --- runtime references -------------------------------------------------
var player : Area2D
var last_origin  # will hold the top-left cell of the last built region

# --- signals ------------------------------------------------------------
signal grid_initialized

# --- respawn tracking ---------------------------------------------------
# (we use one-shot timers to restore tiles after they’re gathered)

func _ready() -> void:
	player = $"../Player"
	# rebuild when window is resized
	get_tree().root.size_changed.connect(initialize_grid)

	# enable processing so we can watch the camera
	set_process(true)

	# initial build
	initialize_grid()
	queue_redraw()
	emit_signal("grid_initialized")

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	# compute what cell the top-left of the camera view sits in
	var vsz := get_viewport_rect().size
	var world_size := vsz * cam.zoom
	var origin_world := cam.global_position - world_size * 0.5
	var origin_cell := Vector2i(
		int(floor(origin_world.x / cell_size.x)),
		int(floor(origin_world.y / cell_size.y))
	)

	# only rebuild if we've crossed into a new cell block
	if last_origin == null or origin_cell != last_origin:
		initialize_grid()
		last_origin = origin_cell

func initialize_grid() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	# --- calculate region around camera -------------------------------
	var vsz := get_viewport_rect().size
	var world_size := vsz * cam.zoom
	# use ceil+1 to add a 1-cell buffer on each axis
	var gx := int(ceil(world_size.x / cell_size.x)) + 1
	var gy := int(ceil(world_size.y / cell_size.y)) + 1
	grid_size = Vector2i(gx, gy)

	var origin_world := cam.global_position - world_size * 0.5
	var origin_cell := Vector2i(
		int(floor(origin_world.x / cell_size.x)),
		int(floor(origin_world.y / cell_size.y))
	)

	astar_grid.region        = Rect2i(origin_cell.x, origin_cell.y, grid_size.x, grid_size.y)
	astar_grid.cell_size     = cell_size
	astar_grid.offset        = cell_size * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

	# --- mark solid tiles within that region --------------------------
	var tm         := $TileMapLayer
	var phys_layer := 0
	for lx in range(grid_size.x):
		for ly in range(grid_size.y):
			var cell = Vector2i(origin_cell.x + lx, origin_cell.y + ly)
			var data : TileData = tm.get_cell_tile_data(cell)
			if data and data.get_collision_polygons_count(phys_layer) > 0:
				astar_grid.set_point_solid(cell, true)

	queue_redraw()
	emit_signal("grid_initialized")

# Schedule a tile to be restored after [delay] seconds,
# and re-enable its A* solidity.
func schedule_respawn(cell: Vector2i, source_id: int, atlas_coords: Vector2i, delay: float) -> void:
	var timer = get_tree().create_timer(delay)
	# bind our arguments into the Callable instead of using varray()
	var cb = Callable(self, "_on_respawn_timeout").bind(cell, source_id, atlas_coords)
	timer.connect("timeout", cb)

func _on_respawn_timeout(cell: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	var tm = $TileMapLayer
	tm.set_cell(cell, source_id, atlas_coords)
	tm.update_internals()
	astar_grid.set_point_solid(cell, true)
