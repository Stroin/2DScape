# res://Scripts/ResourceGatherer.gd
extends Node
class_name ResourceGatherer

# --- exported node paths -----------------------------------------------
@export var player_path       : NodePath
@export var grid_manager_path : NodePath
@export var tile_size         : int     = 64   # must match PlayerMovement.tile_size

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")
@onready var player       : PlayerMovement = get_node(player_path) as PlayerMovement
@onready var grid_manager : GridManager    = get_node(grid_manager_path) as GridManager

func _ready() -> void:
	player.gather_requested.connect(_on_gather_requested)
	print("🔧 ResourceGatherer ready. Listening to:", player)

func _on_gather_requested(cell: Vector2i, ray: RayCast2D) -> void:
	print("ResourceGatherer: gather requested at", cell)
	var info: Dictionary = TileQueries.get_resource_data_from_ray(ray)
	if info.is_empty():
		print("ResourceGatherer: nothing to gather at", cell)
		return

	var res   : ResourceData  = info["resource"]
	var tcell : Vector2i      = info["cell"]
	var tm    : TileMapLayer  = info["tilemap"]
	print("ResourceGatherer: found resource", res.id, "at", tcell, "- gathering will take", res.gather_time, "s")

	var timer = get_tree().create_timer(res.gather_time)
	await timer.timeout
	print("ResourceGatherer:", res.id, "gather timer complete for", tcell)

	# swap tile atlas coords
	var source_id : int      = tm.get_cell_source_id(tcell)
	var old_atlas : Vector2i = tm.get_cell_atlas_coords(tcell)
	var new_atlas : Vector2i = res.atlas_coords
	tm.set_cell(tcell, source_id, new_atlas)
	tm.update_internals()
	print("ResourceGatherer: swapped tile at", tcell, "from", old_atlas, "to", new_atlas)

	# immediately clear the A* solid-flag so player can step on it
	grid_manager.astar_grid.set_point_solid(tcell, false)
	print("ResourceGatherer: cleared solid flag in A* for", tcell)

	# spawn drop
	if res.drop_scene:
		var drop = res.drop_scene.instantiate()
		var global_cell_pos = tm.to_global(tm.map_to_local(tcell))
		drop.global_position = global_cell_pos + Vector2.ONE * tile_size * 0.5
		tm.get_parent().add_child(drop)
		print("ResourceGatherer: spawned drop for", res.id, "at", global_cell_pos)
