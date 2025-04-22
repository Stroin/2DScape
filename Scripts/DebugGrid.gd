extends Node2D
class_name DebugGrid

# --- exported paths -----------------------------------------------------
@export var grid_manager_path : NodePath

# --- cached references --------------------------------------------------
var grid_size : Vector2i
var cell_size : Vector2i


# -----------------------------------------------------------------------
func _ready() -> void:
	var gm := get_node(grid_manager_path)
	grid_size = gm.grid_size
	cell_size = gm.cell_size

	gm.grid_initialized.connect(_on_grid_initialized)
	queue_redraw()


# -----------------------------------------------------------------------
func _on_grid_initialized() -> void:
	var gm := get_node(grid_manager_path)
	grid_size = gm.grid_size
	cell_size = gm.cell_size
	queue_redraw()


# -----------------------------------------------------------------------
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
