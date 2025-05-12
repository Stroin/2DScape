extends Node2D
class_name PathfindingController

signal interact_requested(interactable_type: String, cell: Vector2i)

# --- exported node paths ------------------------------------------------
@export var grid_manager_path : NodePath
@export var player_path       : NodePath
@export var interactable_tilemap_paths: Array[NodePath] = []

# --- cached grid data ---------------------------------------------------
var astar_grid : AStarGrid2D
var cell_size  : Vector2i

# --- runtime references -------------------------------------------------
var player                    : Area2D
var tilemaps                  = []
var _pending_interact_type    : String    = ""
var _pending_interact_cell    : Vector2i  = Vector2i(-1, -1)

func _ready() -> void:
	var gm = get_node(grid_manager_path) as GridManager
	astar_grid = gm.astar_grid
	cell_size  = gm.cell_size

	tilemaps.clear()
	for path in interactable_tilemap_paths:
		tilemaps.append(get_node(path) as TileMapLayer)

	player = get_node(player_path)
	player.connect("gather_requested", Callable(self, "_on_player_arrived"))
	print("🔧 PathfindingController ready. Player:", player, "TileMaps:", tilemaps)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos    : Vector2  = get_global_mouse_position()
		var clicked_cell : Vector2i = _world_to_cell(world_pos)
		if not astar_grid.is_in_boundsv(clicked_cell):
			return

		# --- interactable detection across multiple layers -----------
		var td_inter      = null
		var inter         = ""
		var inter_cell    : Vector2i
		for tm in tilemaps:
			var map_coords = tm.local_to_map(tm.to_local(world_pos))
			td_inter = tm.get_cell_tile_data(map_coords)
			if td_inter:
				inter = td_inter.get_custom_data("interactable_type")
				if typeof(inter) == TYPE_STRING and inter != "":
					inter_cell = map_coords
					break
		if td_inter and inter != "":
			var start_cell  : Vector2i = _world_to_cell(player.position)
			# Always path to the clicked 16×16 cell
			var target_cell : Vector2i = _nearest_reachable_neighbour(clicked_cell, start_cell)
			if target_cell == Vector2i(-1, -1):
				return
			var path = astar_grid.get_point_path(start_cell, target_cell)
			if path.size() > 0:
				print("PathfindingController: clicked interactable:", inter, "at", clicked_cell)
				_pending_interact_type = inter
				_pending_interact_cell = clicked_cell
				player.follow_path(path, clicked_cell)
			return

		# --- resource detection across multiple layers --------------------
		var td_res    = null
		var res_id    = ""
		var res_cell  : Vector2i
		for tm in tilemaps:
			var map_coords = tm.local_to_map(tm.to_local(world_pos))
			td_res = tm.get_cell_tile_data(map_coords)
			if td_res:
				res_id = td_res.get_custom_data("resource_type")
				if typeof(res_id) == TYPE_STRING and res_id != "":
					res_cell = map_coords
					break

		var is_resource = res_id != ""
		print("PathfindingController: clicked_cell=", clicked_cell, " is_resource=", is_resource)

		# --- decide target & look-at cell ------------------------------
		var start_cell  : Vector2i = _world_to_cell(player.position)
		var target_cell : Vector2i = clicked_cell
		var look_at     : Vector2i = Vector2i(-1, -1)

		if is_resource:
			# Always path to the clicked 16×16 cell
			look_at     = clicked_cell
			target_cell = _nearest_reachable_neighbour(clicked_cell, start_cell)
			print("PathfindingController: stand_spot=", target_cell)
			if target_cell == Vector2i(-1, -1):
				return

		var path = astar_grid.get_point_path(start_cell, target_cell)
		print("PathfindingController: path=", path)
		if path.size() > 0:
			print("PathfindingController: calling follow_path()")
			player.follow_path(path, look_at)

func _on_player_arrived(cell: Vector2i, ray: RayCast2D) -> void:
	if cell == _pending_interact_cell and _pending_interact_type != "":
		emit_signal("interact_requested", _pending_interact_type, cell)
		_pending_interact_type = ""
		_pending_interact_cell = Vector2i(-1, -1)

func _world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / cell_size.x)), int(floor(p.y / cell_size.y)))

func _nearest_reachable_neighbour(tree: Vector2i, start: Vector2i) -> Vector2i:
	# Breadth-first expand from the clicked cell until we find the nearest non-solid cell reachable by the player:
	var visited = { tree: true }
	var queue   = [ tree ]
	while queue.size() > 0:
		var cell = queue.pop_front()
		if astar_grid.is_in_boundsv(cell) and not astar_grid.is_point_solid(cell):
			var path = astar_grid.get_point_path(start, cell)
			if path.size() > 0:
				return cell
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var adj = cell + dir
			if not visited.has(adj):
				visited[adj] = true
				queue.append(adj)
	return Vector2i(-1, -1)
