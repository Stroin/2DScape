# res://Scripts/Interactable.gd
extends Area2D
class_name Interactable

# what kind of interaction this is (e.g. "tree", "ore", "crafting_table")
@export var interactable_type: String = ""

# (optional) drag-and-drop your ResourceData .tres here for direct lookup
@export var resource_data: ResourceData

# emitted when the player clicks this object
signal interact_requested(interactable: Interactable)

func _ready() -> void:
	input_pickable = true
	connect("input_event", Callable(self, "_on_input_event"))
	add_to_group("interactable")

func _on_input_event(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("interact_requested", self)
