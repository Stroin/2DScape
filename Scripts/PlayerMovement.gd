# res://Scripts/PlayerMovement.gd

extends Area2D
class_name PlayerMovement

signal gather_requested(cell: Vector2i, ray: RayCast2D)
signal movement_started

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64      # your tile dimension

# --- exported node paths -----------------------------------------------
@export var tilemap_path: NodePath = "../GridManager/TileMapLayer"

# --- runtime state ------------------------------------------------------
var moving                : bool                 = false
var _look_at_cell         : Vector2i             = Vector2i(-1, -1)
var pending_path          : PackedVector2Array   = PackedVector2Array()
var pending_resource_cell : Vector2i             = Vector2i(-1, -1)

# --- references ---------------------------------------------------------
@onready var ray      : RayCast2D       = $RayCast2D
@onready var anim     : AnimationPlayer = $AnimationPlayer
var tilemap : TileMapLayer

func _ready() -> void:
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5
	tilemap = get_node(tilemap_path) as TileMapLayer
	if tilemap == null:
		push_error("PlayerMovement: could not find TileMapLayer at '%s'" % tilemap_path)

func follow_path(path: PackedVector2Array, resource_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if moving:
		# trim any waypoints we’ve already reached (avoid big jumps on diagonal)
		var start_idx: int = 0
		for i in range(path.size()):
			if path[i].distance_to(position) > 0.1:
				start_idx = i
				break
		var trimmed: PackedVector2Array = PackedVector2Array()
		for j in range(start_idx, path.size()):
			trimmed.append(path[j])
		pending_path = trimmed
		pending_resource_cell = resource_cell
		return

	pending_path = PackedVector2Array()
	pending_resource_cell = Vector2i(-1, -1)
	_look_at_cell = resource_cell

	if path.size() <= 1:
		# already on tile
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
	anim.play(_dir_from_vector(dir))
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

	ray.target_position = delta
	ray.force_raycast_update()
	anim.play(_dir_from_vector(delta))

	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", target_pos, 1.0 / animation_speed).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if pending_path.size() > 0:
		moving = false
		follow_path(pending_path, pending_resource_cell)
		return
	_step_through(path, idx + 1)

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0.0 else "left"
	else:
		return "down"  if v.y > 0.0 else "up"
