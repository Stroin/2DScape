# Player.gd
extends Area2D

var animation_speed: float = 2.0
var moving: bool = false
var tile_size: int = 64
var inputs := {
	"right": Vector2.RIGHT,
	"left":  Vector2.LEFT,
	"up":    Vector2.UP,
	"down":  Vector2.DOWN
}

@onready var ray: RayCast2D = $RayCast2d
@onready var anim: AnimationPlayer =$AnimationPlayer

func _ready():
	#snapuje do grida zeby player byl po srodku
	position = position.snapped(Vector2.ONE * tile_size) + Vector2.ONE * tile_size * 0.5

func _unhandled_input(event):
	if moving:
		return
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			_move_grid(inputs[dir])

func _move_grid(dir_vec: Vector2):
	ray.target_position = dir_vec * tile_size
	ray.force_raycast_update()
	if ray.is_colliding():
		return
	moving = true
	anim.play(_dir_from_vector(dir_vec))
	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", position + dir_vec * tile_size, 1.0/animation_speed).set_trans(Tween.TRANS_SINE)
	await tw.finished
	moving = false

func follow_path(path: PackedVector2Array):
	if moving or path.size() < 2:
		return
	moving = true
	_step_through(path, 1)

func _step_through(path: PackedVector2Array, idx: int):
	if idx >= path.size():
		moving = false
		return

	var target_pos: Vector2 = path[idx]
	var delta = target_pos - position

	# raycast sprawdza sciany
	ray.target_position = delta
	ray.force_raycast_update()
	if ray.is_colliding():
		moving = false
		return

	anim.play(_dir_from_vector(delta))
	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", target_pos, 1.0/animation_speed).set_trans(Tween.TRANS_SINE)
	await tw.finished

	_step_through(path, idx + 1)

func _dir_from_vector(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0 else "left"
	else:
		return "down" if v.y > 0 else "up"
