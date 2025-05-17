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
		print("➡️ Click at world pos:", world_pos)
		var clicked_cell : Vector2i = _world_to_cell(world_pos)
		print("   -> clicked_cell:", clicked_cell, "in bounds?", astar_grid.is_in_boundsv(clicked_cell))
		if not astar_grid.is_in_boundsv(clicked_cell):
			return

		# ---- interactable detection -----------------------------------
		var query = PhysicsPointQueryParameters2D.new()
		query.position           = world_pos
		query.collide_with_areas = true
		var hits : Array         = get_world_2d().direct_space_state.intersect_point(query)

		var node : Interactable = null
		for hit in hits:
			if hit.collider is Interactable:
				node = hit.collider
				break

		if node:
			print("🔍 Found interactable:", node.interactable_type, "at cell:", clicked_cell)
			var start_cell : Vector2i = _world_to_cell(player.position)
			print("   -> start_cell:", start_cell)

			# gather all grid cells covered by this interactable’s CollisionShape2D
			var region_cells := []
			var shape_node = node.get_node_or_null("CollisionShape2D")
			if shape_node and shape_node.shape:
				var aabb = shape_node.shape.get_rect()
				var gt = shape_node.get_global_transform()
				var p0 = gt * aabb.position
				var p1 = gt * (aabb.position + Vector2(aabb.size.x, 0))
				var p2 = gt * (aabb.position + Vector2(0, aabb.size.y))
				var p3 = gt * (aabb.position + aabb.size)
				var min_x = min(p0.x, p1.x, p2.x, p3.x)
				var max_x = max(p0.x, p1.x, p2.x, p3.x)
				var min_y = min(p0.y, p1.y, p2.y, p3.y)
				var max_y = max(p0.y, p1.y, p2.y, p3.y)
				var sx = int(floor(min_x / cell_size.x))
				var ex = int(floor(max_x / cell_size.x))
				var sy = int(floor(min_y / cell_size.y))
				var ey = int(floor(max_y / cell_size.y))
				for x in range(sx, ex + 1):
					for y in range(sy, ey + 1):
						region_cells.append(Vector2i(x, y))
			else:
				region_cells.append(clicked_cell)

			# pick the reachable neighbour with shortest path from the region
			var best_len = 1000000
			var best_n = Vector2i(-1, -1)
			var best_path = PackedVector2Array()
			for rc in region_cells:
				var n = _nearest_reachable_neighbour(rc, start_cell)
				if n != Vector2i(-1, -1):
					var p = astar_grid.get_point_path(start_cell, n)
					if p.size() > 0 and p.size() < best_len:
						best_len = p.size()
						best_n = n
						best_path = p
			if best_n == Vector2i(-1, -1):
				print("   ✖ no reachable neighbour for region")
				return

			_pending_interactable  = node
			_pending_interact_cell = best_n
			player.follow_path(best_path, best_n)
			return

		# ---- plain ground movement ------------------------------------
		var start_cell : Vector2i = _world_to_cell(player.position)
		var path       = astar_grid.get_point_path(start_cell, clicked_cell)
		print("🏞️ Ground move: start", start_cell, "to", clicked_cell, "-> path len", path.size())
		if path.size() > 0:
			_pending_interactable  = null
			_pending_interact_cell = Vector2i(-1, -1)
			player.follow_path(path)

func _on_player_arrived(cell: Vector2i, _ray: RayCast2D) -> void:
	if _pending_interactable and cell == _pending_interact_cell:
		emit_signal("interact_requested", _pending_interactable, cell)
		_pending_interactable  = null
		_pending_interact_cell = Vector2i(-1, -1)

func _world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / cell_size.x)), int(floor(p.y / cell_size.y)))

func _nearest_reachable_neighbour(tree: Vector2i, start: Vector2i) -> Vector2i:
	var best_target := Vector2i(-1, -1)
	var best_len    := 1000000
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var adj : Vector2i = tree + d   # explicit type so inference is clear
		if not astar_grid.is_in_boundsv(adj) or astar_grid.is_point_solid(adj):
			continue
		var p := astar_grid.get_point_path(start, adj)
		if p.size() == 0:
			continue
		if p.size() < best_len:
			best_len    = p.size()
			best_target = adj
	return best_target
