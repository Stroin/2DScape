# res://Scripts/DebugGrid.gd

extends Node2D
class_name DebugGrid

# --- exported paths -----------------------------------------------------
@export var grid_manager_path : NodePath

# --- cached references --------------------------------------------------
var grid_size   : Vector2i
var cell_size   : Vector2i
var origin_cell : Vector2i

func _ready() -> void:
	var gm := get_node(grid_manager_path)
	gm.grid_initialized.connect(_on_grid_initialized)
	_on_grid_initialized()  # initial draw

func _on_grid_initialized() -> void:
	var gm     := get_node(grid_manager_path)
	var region : Rect2i = gm.astar_grid.region

	# region.position is the top-left cell in world-space
	origin_cell = region.position
	# region.size is the number of cells in x/y
	grid_size   = region.size
	cell_size   = gm.cell_size

	# offset this Node2D so that its (0,0) aligns with the region origin
	position = Vector2(
		origin_cell.x * cell_size.x,
		origin_cell.y * cell_size.y
	)

	queue_redraw()

func _draw() -> void:
	# vertical lines
	for x in range(grid_size.x + 1):
		draw_line(
			Vector2(x * cell_size.x, 0),
			Vector2(x * cell_size.x, grid_size.y * cell_size.y),
			Color(0.4, 0.4, 0.4),
			1
		)

	# horizontal lines
	for y in range(grid_size.y + 1):
		draw_line(
			Vector2(0, y * cell_size.y),
			Vector2(grid_size.x * cell_size.x, y * cell_size.y),
			Color(0.4, 0.4, 0.4),
			1
		)
