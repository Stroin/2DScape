# PlayerMovement.gd
extends Area2D
class_name PlayerMovement

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64

# --- runtime state ------------------------------------------------------
var moving          : bool  = false
var _look_at_cell   : Vector2i = Vector2i(-1, -1)   # cell to face after path

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")

@onready var ray  : RayCast2D       = $RayCast2d
@onready var anim : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# snap to the centre of the starting tile
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5

# -----------------------------------------------------------------------
# Path-finding movement (point–and-click only)
# -----------------------------------------------------------------------
func follow_path(
		path: PackedVector2Array,
		tree_cell: Vector2i = Vector2i(-1, -1)
	) -> void:
	if moving:
		return

	# Case A – already on target tile
	if path.size() <= 1:
		if tree_cell != Vector2i(-1, -1):
			_face_cell(tree_cell)
			_check_front_for_tree()
		return

	# Case B – multi-tile path
	_look_at_cell = tree_cell
	moving        = true
	_step_through(path, 1)

func _face_cell(cell: Vector2i) -> void:
	var centre : Vector2 = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5
	var dir    : Vector2 = centre - position
	anim.play(_dir_from_vector(dir))
	ray.target_position = dir
	ray.force_raycast_update()

func _step_through(path: PackedVector2Array, idx: int) -> void:
	if idx >= path.size():
		moving = false
		# face the tree, if any
		if _look_at_cell != Vector2i(-1, -1):
			var centre = Vector2(_look_at_cell) * tile_size + Vector2.ONE * tile_size * 0.5
			var dir    = centre - position
			anim.play(_dir_from_vector(dir))
			ray.target_position = dir
			ray.force_raycast_update()
			_look_at_cell = Vector2i(-1, -1)
		_check_front_for_tree()
		return

	var target_pos = path[idx]
	var delta      = target_pos - position

	ray.target_position = delta
	ray.force_raycast_update()

	anim.play(_dir_from_vector(delta))

	var tw = get_tree().create_tween()
	tw.tween_property(
		self, "position", target_pos,
		1.0 / animation_speed
	).set_trans(Tween.TRANS_SINE)
	await tw.finished

	_step_through(path, idx + 1)

# -----------------------------------------------------------------------
# helpers
# -----------------------------------------------------------------------
func _check_front_for_tree() -> void:
	ray.force_raycast_update()
	TileQueries.check_tree_from_ray(ray)

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0.0 else "left"
	else:
		return "down"  if v.y > 0.0 else "up"
