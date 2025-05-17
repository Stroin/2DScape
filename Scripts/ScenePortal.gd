extends Area2D
class_name ScenePortal

@export_file("*.tscn") var target_scene: String
@export var player_path: NodePath

var _player: Area2D = null

func _ready() -> void:
	_player = get_node_or_null(player_path) as Area2D
	if not _player:
		push_warning("ScenePortal: player_path is not set or invalid!")
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	if area == _player and target_scene != "":
		call_deferred("_deferred_change_scene")

func _deferred_change_scene() -> void:
	get_tree().change_scene_to_file(target_scene)
