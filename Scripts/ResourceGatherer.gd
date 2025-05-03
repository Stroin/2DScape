extends Node
class_name ResourceGatherer

# --- exported node paths -----------------------------------------------
@export var player_path        : NodePath
@export var grid_manager_path  : NodePath
@export var tile_size          : int       = 64   # must match PlayerMovement.tile_size
@export var spawn_world_drops  : bool      = true

var gather_cancelled: bool = false
var is_gathering: bool    = false

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")
@onready var player       : PlayerMovement = get_node(player_path) as PlayerMovement
@onready var grid_manager : GridManager    = get_node(grid_manager_path) as GridManager

func _ready() -> void:
	player.gather_requested.connect(_on_gather_requested)
	player.movement_started.connect(_on_player_moved)

func _on_gather_requested(cell: Vector2i, ray: RayCast2D) -> void:
	# prevent concurrent gathers
	if is_gathering:
		return

	# find resource under ray
	var info: Dictionary = TileQueries.get_resource_data_from_ray(ray)
	if info.is_empty():
		print("ResourceGatherer: nothing to gather at", cell)
		return

	var res   : ResourceData  = info["resource"]
	var tcell : Vector2i      = info["cell"]
	var tm    : TileMapLayer  = info["tilemap"]
	print("ResourceGatherer: found resource", res.id, "→ will drop", res.drop_item_id,
		  "- gathering takes", res.gather_time, "s")

	# require proper tool
	if res.required_tool != "" and not Inv.get_items().has(res.required_tool):
		print("ResourceGatherer: You need a %s to gather this resource!" % res.required_tool)
		return

	# require minimum skill level
	if res.required_level > 0 and Stats.get_level(res.skill) < res.required_level:
		print("ResourceGatherer: You need %s level %d to gather this resource!" %
			  [res.skill.capitalize(), res.required_level])
		return

	gather_cancelled = false
	is_gathering    = true

	# wait gather_time
	var timer = get_tree().create_timer(res.gather_time)
	await timer.timeout
	if gather_cancelled:
		print("ResourceGatherer: gathering cancelled due to movement")
		is_gathering     = false
		gather_cancelled = false
		return

	print("ResourceGatherer:", res.id, "gather timer complete for", tcell)

	# drain tool durability
	if res.required_tool != "":
		ToolManager._instance.reduce_durability(res.required_tool, res.tool_durability_cost)

	# swap tile and clear A* solidity
	var source_id : int      = tm.get_cell_source_id(tcell)
	var old_atlas : Vector2i = tm.get_cell_atlas_coords(tcell)
	tm.set_cell(tcell, source_id, res.atlas_coords)
	tm.update_internals()
	grid_manager.astar_grid.set_point_solid(tcell, false)

	# schedule respawn and show countdown
	grid_manager.schedule_respawn(tcell, source_id, old_atlas, res.respawn_time)
	_start_respawn_countdown(tcell, res.respawn_time)

	# add to inventory
	if res.drop_item_id != "":
		Inv.add_item(res.drop_item_id, res.drop_amount)
		print("ResourceGatherer: added %d x %s to inventory" %
			  [res.drop_amount, res.drop_item_id])
	else:
		push_warning("ResourceGatherer: ResourceData.drop_item_id not set for %s" % res.id)

	# grant XP
	if res.skill != "":
		Stats.add_xp(res.skill, res.xp_reward)
		print("ResourceGatherer: granted %.1f XP to %s" %
			  [res.xp_reward, res.skill])

	# optional world-drop
	if spawn_world_drops and res.drop_scene:
		var drop = res.drop_scene.instantiate()
		var global_cell_pos = tm.to_global(tm.map_to_local(tcell))
		drop.global_position = global_cell_pos + Vector2.ONE * tile_size * 0.5
		tm.get_parent().add_child(drop)
		print("ResourceGatherer: spawned drop for", res.id, "at", global_cell_pos)

	is_gathering = false

func _on_player_moved() -> void:
	gather_cancelled = true
	is_gathering    = false

func _start_respawn_countdown(cell: Vector2i, duration: float) -> void:
	var lbl = Label.new()
	grid_manager.add_child(lbl)

	# compute world-space center of that tile
	var world_pos = Vector2(cell.x, cell.y) * tile_size + Vector2.ONE * tile_size * 0.5
	lbl.position = world_pos

	var remaining := int(ceil(duration))
	while remaining > 0:
		lbl.text = str(remaining)
		await get_tree().create_timer(1).timeout
		remaining -= 1

	lbl.queue_free()
