extends Node2D
class_name PathfindingController

# --- exported node paths ------------------------------------------------
@export var grid_manager_path : NodePath
@export var player_path       : NodePath

# --- cached grid data ---------------------------------------------------
var astar_grid : AStarGrid2D
var cell_size  : Vector2i

# --- runtime references -------------------------------------------------
var player  : Area2D
var tilemap : TileMapLayer


# -----------------------------------------------------------------------
func _ready() -> void:
	var gm := get_node(grid_manager_path) as GridManager
	astar_grid = gm.astar_grid
	cell_size  = gm.cell_size
	tilemap    = gm.get_node("TileMapLayer") as TileMapLayer  # adjust if needed
	player     = get_node(player_path)


# -----------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:

		var world_pos    : Vector2  = get_global_mouse_position()
		var clicked_cell : Vector2i = _world_to_cell(world_pos)
		if !astar_grid.is_in_boundsv(clicked_cell):
			return

		# --- tree detection --------------------------------------------
		var td      := tilemap.get_cell_tile_data(clicked_cell)
		var is_tree : bool = td != null and td.get_custom_data("is_tree")

		# --- decide target & look‑at cell ------------------------------
		var start_cell  : Vector2i = _world_to_cell(player.position)
		var target_cell : Vector2i = clicked_cell       # default
		var look_at     : Vector2i = Vector2i(-1, -1)   # default

		if is_tree:
			look_at     = clicked_cell
			target_cell = _nearest_reachable_neighbour(clicked_cell, start_cell)
			if target_cell == Vector2i(-1, -1):
				return   # surrounded – nowhere to stand

		# --- path‑find and send to player ------------------------------
		var path := astar_grid.get_point_path(start_cell, target_cell)
		if path.size() > 0:   # allow “size == 1” to trigger facing only
			player.call_deferred("follow_path", path, look_at)


# -----------------------------------------------------------------------
# helpers
# -----------------------------------------------------------------------
func _world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(p.x / cell_size.x)),
		int(floor(p.y / cell_size.y))
	)


func _nearest_reachable_neighbour(tree: Vector2i, start: Vector2i) -> Vector2i:
	var best_target : Vector2i = Vector2i(-1, -1)
	var best_len    : int      = 1_000_000

	var dirs : Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i.UP,   Vector2i.DOWN
	]

	for d : Vector2i in dirs:
		var adj : Vector2i = tree + d
		if !astar_grid.is_in_boundsv(adj):
			continue
		if astar_grid.is_point_solid(adj):
			continue

		var p := astar_grid.get_point_path(start, adj)
		if p.is_empty():
			continue

		if p.size() < best_len:
			best_len    = p.size()
			best_target = adj

	return best_target
