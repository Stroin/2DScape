# Main.gd
extends Node2D

@export var cell_size: Vector2i = Vector2i(64, 64)

var astar_grid: AStarGrid2D = AStarGrid2D.new()
var grid_size: Vector2i
var player: Area2D

func _ready():
	player = $Player
	get_tree().root.size_changed.connect(initialize_grid)
	initialize_grid()
	queue_redraw()

func initialize_grid():
	grid_size = Vector2i(get_viewport_rect().size) / cell_size
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size * 0.5
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var clicked_cell = Vector2i(event.position) / cell_size
		if not astar_grid.is_in_boundsv(clicked_cell):
			return

		var size2 = Vector2(cell_size.x, cell_size.y)
		var offset = size2 * 0.5
		var fp = ((player.position - offset) / size2).floor()
		var start_cell = Vector2i(fp.x, fp.y)

		var raw_path: PackedVector2Array = astar_grid.get_point_path(start_cell, clicked_cell)
		if raw_path.size() > 1:
			player.call_deferred("follow_path", raw_path)

func _draw():
	for x in range(grid_size.x + 1):
		draw_line(
			Vector2(x * cell_size.x, 0),
			Vector2(x * cell_size.x, grid_size.y * cell_size.y),
			Color(0.2, 0.2, 0.2),
			2.0
		)
	for y in range(grid_size.y + 1):
		draw_line(
			Vector2(0, y * cell_size.y),
			Vector2(grid_size.x * cell_size.x, y * cell_size.y),
			Color(0.2, 0.2, 0.2),
			2.0
		)
	# draw solid cells (walls)
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if astar_grid.is_point_solid(Vector2i(x, y)):
				draw_rect(
					Rect2(x * cell_size.x, y * cell_size.y, cell_size.x, cell_size.y),
					Color(0.1, 0.1, 0.1)
				)
