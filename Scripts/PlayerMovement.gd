extends Area2D
class_name PlayerMovement

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64

# --- runtime state ------------------------------------------------------
var moving          : bool  = false
var _look_at_cell   : Vector2i = Vector2i(-1, -1)   # cell to face after path

# --- input map ----------------------------------------------------------
var inputs := {
	"right": Vector2.RIGHT,
	"left":  Vector2.LEFT,
	"up":    Vector2.UP,
	"down":  Vector2.DOWN
}

# --- references ---------------------------------------------------------
const TileQueries = preload("res://Scripts/TileQueries.gd")

@onready var ray  : RayCast2D       = $RayCast2d
@onready var anim : AnimationPlayer = $AnimationPlayer


# -----------------------------------------------------------------------

func _ready() -> void:
	# snap to the centre of the starting tile
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5


func _unhandled_input(event) -> void:
	if moving:
		return
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			_move_grid(inputs[dir])


# -----------------------------------------------------------------------
# Single–tile keyboard movement
# -----------------------------------------------------------------------
func _move_grid(dir_vec: Vector2) -> void:
	ray.target_position = dir_vec * tile_size
	ray.force_raycast_update()

	# If the tile we are trying to enter is a tree, detect it immediately.
	if ray.is_colliding():
		TileQueries.check_tree_from_ray(ray)
		return

	moving = true
	anim.play(_dir_from_vector(dir_vec))

	var tw = get_tree().create_tween()
	tw.tween_property(
		self, "position", position + dir_vec * tile_size,
		1.0 / animation_speed
	).set_trans(Tween.TRANS_SINE)
	await tw.finished

	moving = false
	_check_front_for_tree()              # one final check after arriving


# -----------------------------------------------------------------------
# Path‑finding movement (point–and‑click)
# -----------------------------------------------------------------------
func follow_path(
		path: PackedVector2Array,
		tree_cell: Vector2i = Vector2i(-1, -1)
	) -> void:
	if moving:
		return

	# ---------------------------------------------
	# Case A – we’re already on the target tile
	# ---------------------------------------------
	if path.size() <= 1:
		if tree_cell != Vector2i(-1, -1):
			_face_cell(tree_cell)          # turn and run the tree‑check once
			_check_front_for_tree()
		return                             # nothing else to do

	# ---------------------------------------------
	# Case B – normal multi‑tile path
	# ---------------------------------------------
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
	# -------------------------------------------------------------------
	# arrived at final tile
	# -------------------------------------------------------------------
	if idx >= path.size():
		moving = false

		# turn to face the tree we clicked (if any)
		if _look_at_cell != Vector2i(-1, -1):
			var centre : Vector2 = Vector2(_look_at_cell) * tile_size + Vector2.ONE * tile_size * 0.5
			var dir    : Vector2 = centre - position
			anim.play(_dir_from_vector(dir))
			ray.target_position = dir
			ray.force_raycast_update()
			_look_at_cell = Vector2i(-1, -1)

		_check_front_for_tree()      # single check after the whole path
		return

	# -------------------------------------------------------------------
	# stepping to the next waypoint
	# -------------------------------------------------------------------
	var target_pos : Vector2 = path[idx]
	var delta      : Vector2 = target_pos - position

	ray.target_position = delta        # keep ray aligned with movement
	ray.force_raycast_update()         # (no tree‑check here)

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
