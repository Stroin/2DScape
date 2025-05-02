# res://Scripts/ToolPickup.gd

extends Area2D
class_name ToolPickup

# — which tool this is (must match your inventory key, e.g. "axe" or "pickaxe")
@export var tool_id: String = ""

# — how many to give when picked up
@export var tool_amount: int = 1

func _ready() -> void:
	# debug so you can see the pickup exists
	print("ToolPickup: ready, tool_id=", tool_id)
	# listen for other areas entering us
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	# only pick up when the player overlaps
	if area is PlayerMovement:
		Inv.add_item(tool_id, tool_amount)
		print("ToolPickup: picked up %d x %s" % [tool_amount, tool_id])
		queue_free()
