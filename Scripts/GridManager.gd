extends Node2D
class_name GridManager          

@export var cell_size: Vector2i = Vector2i(64, 64)

var astar_grid: AStarGrid2D = AStarGrid2D.new()
var grid_size: Vector2i
var player: Area2D

signal grid_initialized         

func _ready():
	player =  $"../Player"                  
	get_tree().root.size_changed.connect(initialize_grid)
	initialize_grid()
	queue_redraw()
	emit_signal("grid_initialized")

func initialize_grid():
	grid_size = Vector2i(get_viewport_rect().size) / cell_size
	astar_grid.region        = Rect2i(0, 0, grid_size.x, grid_size.y)
	astar_grid.cell_size     = cell_size
	astar_grid.offset        = cell_size * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()
	var tm =    $TileMapLayer            
	var phys_layer = 0 
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = Vector2i(x, y)
			var data: TileData = tm.get_cell_tile_data(cell)
			if data and data.get_collision_polygons_count(phys_layer) > 0:
				astar_grid.set_point_solid(cell, true)
				
	queue_redraw()
	emit_signal("grid_initialized")
