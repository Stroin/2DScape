extends Node2D
class_name PathfindingController

@export var grid_manager_path: NodePath  
@export var player_path:      NodePath    

var astar_grid: AStarGrid2D
var cell_size:  Vector2i
var player:     Area2D

func _ready():
	var gm = get_node(grid_manager_path)
	astar_grid = gm.astar_grid
	cell_size  = gm.cell_size
	player     = get_node(player_path)

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		var world_pos: Vector2 = get_global_mouse_position()
		var clicked_cell = Vector2i(
			int(world_pos.x / cell_size.x),
			int(world_pos.y / cell_size.y)
		)
		if not astar_grid.is_in_boundsv(clicked_cell):
			return
		var start_cell = Vector2i(
			int(player.position.x / cell_size.x),
			int(player.position.y / cell_size.y)
		)
		var raw_path = astar_grid.get_point_path(start_cell, clicked_cell)
		if raw_path.size() > 1:
			player.call_deferred("follow_path", raw_path)
