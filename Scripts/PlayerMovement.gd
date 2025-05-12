extends Area2D
class_name PlayerMovement

signal gather_requested(cell: Vector2i, ray: RayCast2D)
signal movement_started

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0       # tiles per second
var tile_size       : int   = 16        # now 16×16

# --- node references -----------------------------------------------
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var ray    : RayCast2D        = $RayCast2D
@onready var camera : Camera2D         = $Camera2D

# pathing state --------------------------------------------------------
var moving                : bool               = false
var _look_at_cell         : Vector2i           = Vector2i(-1, -1)
var pending_path          : PackedVector2Array = PackedVector2Array()
var pending_resource_cell : Vector2i           = Vector2i(-1, -1)
var last_direction        : Vector2            = Vector2.DOWN

func _ready() -> void:
	# center on tile
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5
	ray.enabled = true

func _process(_delta: float) -> void:
	if not moving:
		_play_idle(last_direction)

func follow_path(path: PackedVector2Array, resource_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if moving:
		# trim already‐reached waypoints
		var start_idx = 0
		for i in range(path.size()):
			if path[i].distance_to(position) > 0.1:
				start_idx = i
				break
		var trimmed = PackedVector2Array()
		for j in range(start_idx, path.size()):
			trimmed.append(path[j])
		pending_path = trimmed
		pending_resource_cell = resource_cell
		return

	pending_path = PackedVector2Array()
	pending_resource_cell = Vector2i(-1, -1)
	_look_at_cell = resource_cell

	if path.size() <= 1:
		# already on the tile
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

	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", target_pos, 1.0 / animation_speed).set_trans(Tween.TRANS_SINE)
	await tw.finished

	if pending_path.size() > 0:
		moving = false
		follow_path(pending_path, pending_resource_cell)
		return

	_step_through(path, idx + 1)

func _play_animation(delta: Vector2) -> void:
	var anim_name := ""
	if abs(delta.x) > abs(delta.y):
		anim_name = "Walk_Side"
		sprite.flip_h = delta.x < 0
	else:
		if delta.y > 0:
			anim_name = "Walk_Down"
		else:
			anim_name = "Walk_Up"
		sprite.flip_h = false
	sprite.play(anim_name)
	last_direction = delta

func _play_idle(delta: Vector2) -> void:
	var anim_name := ""
	if abs(delta.x) > abs(delta.y):
		anim_name = "Idle_Side"
		sprite.flip_h = delta.x < 0
	else:
		if delta.y > 0:
			anim_name = "Idle_Down"
		else:
			anim_name = "Idle_Up"
		sprite.flip_h = false
	sprite.play(anim_name)
