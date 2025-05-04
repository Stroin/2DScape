extends Node
class_name ResourceGatherer

@export var player_path       : NodePath
@export var grid_manager_path : NodePath
@export var tile_size         : int    = 64
@export var spawn_world_drops : bool   = true

var gather_cancelled: bool = false
var is_gathering:    bool = false

const TileQueries = preload("res://Scripts/TileQueries.gd")
@onready var player             : PlayerMovement    = get_node(player_path)
@onready var grid_manager       : GridManager       = get_node(grid_manager_path)
@onready var durability_manager : DurabilityManager = get_node("/root/DurabilityManage")

func _ready() -> void:
	player.gather_requested.connect(_on_gather_requested)
	player.movement_started.connect(_on_player_moved)

func _on_gather_requested(cell: Vector2i, ray: RayCast2D) -> void:
	if is_gathering:
		return

	var info = TileQueries.get_resource_data_from_ray(ray)
	if info.is_empty():
		print("ResourceGatherer: nothing to gather at", cell)
		return

	var res   : ResourceData  = info["resource"]
	var tcell : Vector2i      = info["cell"]
	var tm    : TileMapLayer  = info["tilemap"]

	# --- find a qualifying tool of sufficient tier ---
	var use_tool_id: String = ""
	if res.required_tool:
		var req_tier = res.required_tool.tier
		var best_tier = 0
		for item_id in Inv.get_items().keys():
			var it = ItemManager.get_item(item_id)
			if it and it.category == ItemData.Category.TOOL and it.tier >= req_tier:
				if it.tier > best_tier:
					best_tier = it.tier
					use_tool_id = item_id
		if use_tool_id == "":
			print("ResourceGatherer: Need ", res.required_tool.display_name, " or better to gather!")
			return

	# --- skill requirement check ---
	if res.required_level > 0 and Stats.get_level(res.skill) < res.required_level:
		print("ResourceGatherer: You need %s level %d to gather!" %
			  [res.skill.capitalize(), res.required_level])
		return

	gather_cancelled = false
	is_gathering    = true

	await get_tree().create_timer(res.gather_time).timeout
	if gather_cancelled:
		print("ResourceGatherer: gathering cancelled")
		is_gathering     = false
		gather_cancelled = false
		return

	# --- drain chosen tool’s durability ---
	if use_tool_id != "":
		durability_manager.reduce_durability(use_tool_id, res.tool_durability_cost)

	# --- swap tile & disable A* solidity ---
	var src_id = tm.get_cell_source_id(tcell)
	var old_at = tm.get_cell_atlas_coords(tcell)
	tm.set_cell(tcell, src_id, res.atlas_coords)
	tm.update_internals()
	grid_manager.astar_grid.set_point_solid(tcell, false)

	grid_manager.schedule_respawn(tcell, src_id, old_at, res.respawn_time)
	_start_respawn_countdown(tcell, res.respawn_time)

	# --- add drop to inventory ---
	if res.drop_item:
		Inv.add_item(res.drop_item.id, res.drop_amount)
	else:
		push_warning("ResourceGatherer: no drop_item set for %s" % res.id)

	# --- grant XP ---
	if res.skill != "":
		Stats.add_xp(res.skill, res.xp_reward)

	# --- optional world‐drop spawn ---
	if spawn_world_drops and res.drop_scene:
		var drop = res.drop_scene.instantiate()
		drop.global_position = tm.to_global(tm.map_to_local(tcell)) + Vector2.ONE * tile_size * 0.5
		tm.get_parent().add_child(drop)

	is_gathering = false

func _on_player_moved() -> void:
	gather_cancelled = true
	is_gathering    = false

func _start_respawn_countdown(cell: Vector2i, duration: float) -> void:
	var lbl = Label.new()
	grid_manager.add_child(lbl)
	lbl.position = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5

	var remaining := int(ceil(duration))
	while remaining > 0:
		lbl.text = str(remaining)
		await get_tree().create_timer(1).timeout
		remaining -= 1
	lbl.queue_free()
