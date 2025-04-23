# res://Scripts/PlayerMovement.gd
extends Area2D
class_name PlayerMovement

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64

# --- exported node paths -----------------------------------------------
# Default to the common layout: Player is sibling of GridManager, which has the TileMapLayer child.
@export var tilemap_path : NodePath = "../GridManager/TileMapLayer"

# --- runtime state ------------------------------------------------------
var moving          : bool     = false
var _look_at_cell   : Vector2i = Vector2i(-1, -1)
var _pending_res_id : String   = ""

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")

@onready var ray      : RayCast2D       = $RayCast2d
@onready var anim     : AnimationPlayer = $AnimationPlayer
var tilemap : TileMapLayer

func _ready() -> void:
	# snap to the centre of the starting tile
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5

	# cache the TileMapLayer reference
	tilemap = get_node(tilemap_path) as TileMapLayer
	if tilemap == null:
		push_error("PlayerMovement: could not find TileMapLayer at '" + str(tilemap_path) + "'")

# -----------------------------------------------------------------------
# Path-finding movement (point-and-click only)
# -----------------------------------------------------------------------
func follow_path(
		path: PackedVector2Array,
		resource_cell: Vector2i = Vector2i(-1, -1),
		resource_id: String = ""
	) -> void:
	if moving:
		return

	_pending_res_id = resource_id
	_look_at_cell   = resource_cell

	# Case A – already on tile (face only)
	if path.size() <= 1:
		if _pending_res_id != "":
			_face_cell(_look_at_cell)
			_try_gather()
		return

	# Case B – multi-tile path
	moving = true
	_step_through(path, 1)

func _face_cell(cell: Vector2i) -> void:
	var centre = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5
	var dir    = centre - position
	anim.play(_dir_from_vector(dir))
	ray.target_position = dir
	ray.force_raycast_update()

func _step_through(path: PackedVector2Array, idx: int) -> void:
	if idx >= path.size():
		moving = false
		if _pending_res_id != "":
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

# -----------------------------------------------------------------------
# Helpers for gathering
# -----------------------------------------------------------------------
func _try_gather() -> void:
	if _pending_res_id == "":
		return
	# await the coroutine so we know when it’s done
	if await TileQueries.gather_resource(tilemap, position):
		print("Gathered resource:", _pending_res_id)
	_pending_res_id = ""

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0.0 else "left"
	else:
		return "down"  if v.y > 0.0 else "up"
