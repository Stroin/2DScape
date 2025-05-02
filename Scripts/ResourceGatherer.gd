# res://Scripts/ResourceGatherer.gd

extends Node
class_name ResourceGatherer

# --- exported node paths -----------------------------------------------
@export var player_path        : NodePath
@export var grid_manager_path  : NodePath
@export var tile_size          : int    = 64  # must match PlayerMovement.tile_size
@export var spawn_world_drops  : bool   = true

var gather_cancelled: bool = false

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")
@onready var player       : PlayerMovement = get_node(player_path) as PlayerMovement
@onready var grid_manager : GridManager    = get_node(grid_manager_path) as GridManager

func _ready() -> void:
	player.gather_requested.connect(_on_gather_requested)
	player.movement_started.connect(_on_player_moved)

func _on_gather_requested(cell: Vector2i, ray: RayCast2D) -> void:
	# try to find resource under the player's ray
	var info: Dictionary = TileQueries.get_resource_data_from_ray(ray)
	if info.is_empty():
		print("ResourceGatherer: nothing to gather at", cell)
		return

	var res   : ResourceData  = info["resource"]
	var tcell : Vector2i      = info["cell"]
	var tm    : TileMapLayer  = info["tilemap"]
	print("ResourceGatherer: found resource", res.id, "→ will drop", res.drop_item_id, "- gathering takes", res.gather_time, "s")

	# --- require proper tool --------------------------------------------
	if res.required_tool != "":
		if not Inv.get_items().has(res.required_tool):
			print("ResourceGatherer: You need a %s to gather this resource!" % res.required_tool)
			return

	# --- require minimum skill level ------------------------------------
	if res.required_level > 0 and Stats.get_level(res.skill) < res.required_level:
		print("ResourceGatherer: You need %s level %d to gather this resource!" %
			  [res.skill.capitalize(), res.required_level])
		return

	gather_cancelled = false
	# gathering timer
	var timer = get_tree().create_timer(res.gather_time)
	await timer.timeout
	if gather_cancelled:
		print("ResourceGatherer: gathering cancelled due to movement")
		return

	print("ResourceGatherer:", res.id, "gather timer complete for", tcell)

	# drain tool durability after successful gather
	var used_tool: String = res.required_tool
	ToolManager._instance.reduce_durability(used_tool, res.tool_durability_cost)

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

	# schedule respawn of this resource
	grid_manager.schedule_respawn(tcell, source_id, old_atlas, res.respawn_time)

	# — add the configured drop item into your inventory Autoload (“Inv”) —
	if res.drop_item_id != "":
		Inv.add_item(res.drop_item_id, res.drop_amount)
		print("ResourceGatherer: added %d x %s to inventory" % [res.drop_amount, res.drop_item_id])
	else:
		push_warning("ResourceGatherer: ResourceData.drop_item_id not set for %s" % res.id)

	# — grant XP based on the ResourceData fields —
	if res.skill != "":
		Stats.add_xp(res.skill, res.xp_reward)
		print("ResourceGatherer: granted %.1f XP to %s" % [res.xp_reward, res.skill])

	# optionally spawn a world-drop if enabled
	if spawn_world_drops and res.drop_scene:
		var drop = res.drop_scene.instantiate()
		var global_cell_pos = tm.to_global(tm.map_to_local(tcell))
		drop.global_position = global_cell_pos + Vector2.ONE * tile_size * 0.5
		tm.get_parent().add_child(drop)
		print("ResourceGatherer: spawned drop for", res.id, "at", global_cell_pos)

func _on_player_moved() -> void:
	gather_cancelled = true
