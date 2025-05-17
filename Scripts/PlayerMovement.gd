extends Area2D
class_name PlayerMovement

signal gather_requested(cell: Vector2i, ray: RayCast2D)
signal movement_started

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0       # tiles per second
var tile_size       : int   = 16        # 16×16 grid

# --- node references ----------------------------------------------------
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var ray    : RayCast2D        = $RayCast2D
@onready var camera : Camera2D         = $Camera2D

# --- path-follow state ---------------------------------------------------
var moving                : bool               = false
var _look_at_cell         : Vector2i           = Vector2i(-1, -1)
var pending_path          : PackedVector2Array = PackedVector2Array()
var pending_resource_cell : Vector2i           = Vector2i(-1, -1)
var last_direction        : Vector2            = Vector2.DOWN
var is_forced_animation   : bool               = false

func _ready() -> void:
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5
	ray.enabled = true

func _process(_delta: float) -> void:
	if not moving and not is_forced_animation:
		_play_idle(last_direction)

func follow_path(path: PackedVector2Array, resource_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if moving:
		pending_path          = path
		pending_resource_cell = resource_cell
		return

	pending_path          = PackedVector2Array()
	pending_resource_cell = Vector2i(-1, -1)
	_look_at_cell         = resource_cell

	if path.size() <= 1:
		if _look_at_cell != Vector2i(-1, -1):
			_face_cell(_look_at_cell)
			emit_signal("gather_requested", _look_at_cell, ray)
		return

	emit_signal("movement_started")
	moving = true
	_step_through(path, 1)

func _face_cell(cell: Vector2i) -> void:
	var centre = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5
	var dir    = centre - position
	_play_idle(dir)
	ray.target_position = dir
	ray.force_raycast_update()

func _step_through(path: PackedVector2Array, idx: int) -> void:
	if idx >= path.size():
		moving = false
		if _look_at_cell != Vector2i(-1, -1):
			_face_cell(_look_at_cell)
			emit_signal("gather_requested", _look_at_cell, ray)
		return

	var target_pos = path[idx]
	var delta      = target_pos - position

	_play_animation(delta)
	ray.target_position = delta
	ray.force_raycast_update()

	var distance_tiles : float = delta.length() / tile_size
	var duration       : float = distance_tiles / animation_speed

	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_SINE)
	await tw.finished

	if pending_path.size() > 0:
		var new_path : PackedVector2Array = pending_path
		var new_res  : Vector2i           = pending_resource_cell
		pending_path          = PackedVector2Array()
		pending_resource_cell = Vector2i(-1, -1)

		var next_idx := 0
		while next_idx < new_path.size() and new_path[next_idx].distance_to(position) <= 0.1:
			next_idx += 1

		if next_idx >= new_path.size():
			moving = false
			if new_res != Vector2i(-1, -1):
				_face_cell(new_res)
				emit_signal("gather_requested", new_res, ray)
			return

		_step_through(new_path, next_idx)
		return

	_step_through(path, idx + 1)

func _play_animation(delta: Vector2) -> void:
	var anim_name := ""
	if abs(delta.x) > abs(delta.y):
		anim_name = "Walk_Side"
		sprite.flip_h = delta.x < 0
	else:
		anim_name = "Walk_Down" if delta.y > 0 else "Walk_Up"
		sprite.flip_h = false
	sprite.play(anim_name)
	last_direction = delta

func _play_idle(delta: Vector2) -> void:
	var anim_name := ""
	if abs(delta.x) > abs(delta.y):
		anim_name = "Idle_Side"
		sprite.flip_h = delta.x < 0
	else:
		anim_name = "Idle_Down" if delta.y > 0 else "Idle_Up"
		sprite.flip_h = false
	sprite.play(anim_name)

func play_gather_animation_for(seconds: float) -> void:
	is_forced_animation = true
	var dir = last_direction
	var anim := ""
	if abs(dir.x) > abs(dir.y):
		anim = "Gather_Side"
		sprite.flip_h = dir.x < 0
	else:
		anim = "Gather_Down" if dir.y > 0 else "Gather_Up"
		sprite.flip_h = false
	sprite.play(anim)
	await get_tree().create_timer(seconds).timeout
	is_forced_animation = false
	_play_idle(dir)
