# res://Scripts/PlayerMovement.gd
extends Area2D
class_name PlayerMovement

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64      # your tile dimension

# --- exported node paths -----------------------------------------------
@export var tilemap_path: NodePath = "../GridManager/TileMapLayer"

# --- runtime state ------------------------------------------------------
var moving        : bool     = false
var _look_at_cell : Vector2i = Vector2i(-1, -1)

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")

@onready var ray      : RayCast2D       = $RayCast2D
@onready var anim     : AnimationPlayer = $AnimationPlayer
var tilemap : TileMapLayer

func _ready() -> void:
	print("🔧 PlayerMovement ready on node:", name)
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5
	tilemap = get_node(tilemap_path) as TileMapLayer
	if tilemap == null:
		push_error("PlayerMovement: could not find TileMapLayer at '" + str(tilemap_path) + "'")

func follow_path(path: PackedVector2Array, resource_cell: Vector2i = Vector2i(-1, -1)) -> void:
	print("PlayerMovement: follow_path called. path=", path, " resource_cell=", resource_cell)
	if moving:
		return
	_look_at_cell = resource_cell

	if path.size() <= 1:
		print("PlayerMovement: Case A – already on tile")
		if _look_at_cell != Vector2i(-1, -1):
			_face_cell(_look_at_cell)
			_try_gather()
		return

	print("PlayerMovement: Case B – moving along path")
	moving = true
	_step_through(path, 1)

func _face_cell(cell: Vector2i) -> void:
	print("PlayerMovement: _face_cell at", cell)
	var centre = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5
	var dir    = centre - position
	anim.play(_dir_from_vector(dir))
	ray.target_position = dir
	ray.force_raycast_update()

func _step_through(path: PackedVector2Array, idx: int) -> void:
	if idx >= path.size():
		print("PlayerMovement: reached end of path, idx=", idx)
		moving = false
		if _look_at_cell != Vector2i(-1, -1):
			_face_cell(_look_at_cell)
			_try_gather()
		return

	var target_pos = path[idx]
	var delta      = target_pos - position

	ray.target_position = delta
	ray.force_raycast_update()
	anim.play(_dir_from_vector(delta))

	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", target_pos, 1.0 / animation_speed).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_step_through(path, idx + 1)

func _try_gather() -> void:
	print("PlayerMovement: _try_gather()")
	ray.force_raycast_update()
	print("PlayerMovement: ray.is_colliding() =", ray.is_colliding(), " collider=", ray.get_collider())

	var info: Dictionary = TileQueries.get_resource_data_from_ray(ray)
	print("PlayerMovement: resource_data info =", info)
	if info.is_empty():
		print("PlayerMovement: nothing to gather here.")
		return

	var res  : ResourceData  = info["resource"]
	var cell : Vector2i      = info["cell"]
	var tm   : TileMapLayer  = info["tilemap"]

	print("PlayerMovement: Gathering resource", res.id, "at cell", cell)
	var timer = (Engine.get_main_loop() as SceneTree).create_timer(res.gather_time)
	await timer.timeout

	# swap the tile to this resource’s atlas coords
	var source_id : int      = tm.get_cell_source_id(cell)
	var old_atlas : Vector2i = tm.get_cell_atlas_coords(cell)
	var new_atlas : Vector2i = res.atlas_coords
	tm.set_cell(cell, source_id, new_atlas)
	tm.update_internals()

	print("PlayerMovement:", res.display_name, "gathered! tile swapped from", old_atlas, "to", new_atlas)

	# — immediately clear the A* solid-flag so you can step on it —
	var gm = tm.get_parent() as GridManager
	if gm:
		gm.astar_grid.set_point_solid(cell, false)

	# spawn drop
	if res.drop_scene:
		var drop = res.drop_scene.instantiate()
		var global_cell_pos = tm.to_global(tm.map_to_local(cell))
		drop.global_position = global_cell_pos + Vector2.ONE * tile_size * 0.5
		tm.get_parent().add_child(drop)

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0.0 else "left"
	else:
		return "down"  if v.y > 0.0 else "up"
