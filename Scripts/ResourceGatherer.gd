extends Node
class_name ResourceGatherer

@export var player_path                    : NodePath
@export var grid_manager_path              : NodePath
@export var pathfinding_controller_path    : NodePath
@export var tile_size                      : int    = 64
@export var spawn_world_drops              : bool   = true

var gather_cancelled: bool = false
var is_gathering:    bool = false

@onready var player             : PlayerMovement        = get_node(player_path)
@onready var grid_manager       : GridManager           = get_node(grid_manager_path)
@onready var durability_manager : DurabilityManager     = get_node("/root/DurabilityManage")
@onready var pc                 : PathfindingController = get_node(pathfinding_controller_path)

func _ready() -> void:
	pc.connect("interact_requested", Callable(self, "_on_pc_interact"))
	player.movement_started.connect(Callable(self, "_on_player_moved"))

func _on_pc_interact(interactable: Interactable, cell: Vector2i) -> void:
	if is_gathering:
		return

	var res: ResourceData = interactable.resource_data
	if not res:
		print("ResourceGatherer: nothing to gather at", cell)
		return

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

	# --- hide the resource instance and schedule respawn ---
	interactable.hide()
	var shape = interactable.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = true
	interactable.set_process(false)
	interactable.set_physics_process(false)
	grid_manager.initialize_grid()

	get_tree().create_timer(res.respawn_time).timeout.connect(
		Callable(self, "_on_respawn_timeout").bind(interactable)
	)

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
		drop.global_position = interactable.global_position + Vector2.ONE * tile_size * 0.5
		interactable.get_parent().add_child(drop)

	is_gathering = false

func _on_player_moved() -> void:
	gather_cancelled = true
	is_gathering    = false

func _on_respawn_timeout(interactable: Interactable) -> void:
	var shape = interactable.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = false
	interactable.set_process(true)
	interactable.set_physics_process(true)
	interactable.show()

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
