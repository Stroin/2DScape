# res://Scripts/PlayerMovement.gd
extends Area2D
class_name PlayerMovement

signal gather_requested(cell: Vector2i, ray: RayCast2D)

# --- tuning -------------------------------------------------------------
var animation_speed : float = 2.0     # tiles per second
var tile_size       : int   = 64      # your tile dimension

# --- exported node paths -----------------------------------------------
@export var tilemap_path: NodePath = "../GridManager/TileMapLayer"

# --- runtime state ------------------------------------------------------
var moving        : bool     = false
var _look_at_cell : Vector2i = Vector2i(-1, -1)

# --- references ---------------------------------------------------------
@onready var ray      : RayCast2D       = $RayCast2D
@onready var anim     : AnimationPlayer = $AnimationPlayer
var tilemap : TileMapLayer

func _ready() -> void:
	print("🔧 PlayerMovement ready on node:", name)
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5
	tilemap = get_node(tilemap_path) as TileMapLayer
	if tilemap == null:
		push_error("PlayerMovement: could not find TileMapLayer at '%s'" % tilemap_path)

func follow_path(path: PackedVector2Array, resource_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if moving:
		return
	_look_at_cell = resource_cell

	if path.size() <= 1:
		# already on tile
		if _look_at_cell != Vector2i(-1, -1):
			_face_cell(_look_at_cell)
			emit_signal("gather_requested", _look_at_cell, ray)
		return

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
	_step_through(path, idx + 1)

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0.0 else "left"
	else:
		return "down"  if v.y > 0.0 else "up"
