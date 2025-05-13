# res://Scripts/PathfindingController.gd
extends Node2D
class_name PathfindingController

signal interact_requested(interactable: Interactable, cell: Vector2i)

# --- exported node paths ------------------------------------------------
@export var grid_manager_path : NodePath
@export var player_path       : NodePath

# --- cached grid data ---------------------------------------------------
var astar_grid : AStarGrid2D
var cell_size  : Vector2i

# --- runtime references -------------------------------------------------
var player                 : Area2D
var _pending_interactable  : Interactable   = null
var _pending_interact_cell : Vector2i       = Vector2i(-1, -1)

func _ready() -> void:
	var gm = get_node(grid_manager_path) as GridManager
	astar_grid = gm.astar_grid
	cell_size  = gm.cell_size
	player     = get_node(player_path)
	player.connect("gather_requested", Callable(self, "_on_player_arrived"))
	print("🔧 PathfindingController ready. Player:", player)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos    : Vector2  = get_global_mouse_position()
		var clicked_cell : Vector2i = _world_to_cell(world_pos)
		if not astar_grid.is_in_boundsv(clicked_cell):
			return

		# --- interactable detection ------------------------------------
		var query = PhysicsPointQueryParameters2D.new()
		query.position           = world_pos
		query.collide_with_areas = true
		var hits: Array          = get_world_2d().direct_space_state.intersect_point(query)

		var node: Interactable = null
		for hit in hits:
			if hit.collider is Interactable:
				node = hit.collider
				break

		if node:
			print("PathfindingController: clicked interactable:", node.interactable_type, "at", clicked_cell)
			var is_resource = node.resource_data != null
			print("PathfindingController: clicked_cell=", clicked_cell, " is_resource=", is_resource)

			var start_cell   : Vector2i = _world_to_cell(player.position)
			var target_cell  : Vector2i = _world_to_cell(node.global_position)
			var neighbour    : Vector2i = _nearest_reachable_neighbour(target_cell, start_cell)
			print("PathfindingController: stand_spot=", neighbour)
			if neighbour == Vector2i(-1, -1):
				return

			var path = astar_grid.get_point_path(start_cell, neighbour)
			print("PathfindingController: path=", path)
			if path.size() > 0:
				print("PathfindingController: calling follow_path()")
				_pending_interactable  = node
				_pending_interact_cell = clicked_cell
				player.follow_path(path, clicked_cell)
			return

		# --- ground movement --------------------------------------------
		var start_cell: Vector2i = _world_to_cell(player.position)
		var path       = astar_grid.get_point_path(start_cell, clicked_cell)
		print("PathfindingController: path=", path)
		if path.size() > 0:
			print("PathfindingController: calling follow_path()")
			_pending_interactable  = null
			_pending_interact_cell = Vector2i(-1, -1)
			player.follow_path(path)

func _on_player_arrived(cell: Vector2i, ray: RayCast2D) -> void:
	if _pending_interactable and cell == _pending_interact_cell:
		emit_signal("interact_requested", _pending_interactable, cell)
		_pending_interactable  = null
		_pending_interact_cell = Vector2i(-1, -1)

func _world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / cell_size.x)), int(floor(p.y / cell_size.y)))

func _nearest_reachable_neighbour(tree: Vector2i, start: Vector2i) -> Vector2i:
	var best_target := Vector2i(-1, -1)
	var best_len    := 1_000_000
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var adj = tree + d
		if not astar_grid.is_in_boundsv(adj) or astar_grid.is_point_solid(adj):
			continue
		var p = astar_grid.get_point_path(start, adj)
		if p.size() == 0:
			continue
		if p.size() < best_len:
			best_len    = p.size()
			best_target = adj
	return best_target
