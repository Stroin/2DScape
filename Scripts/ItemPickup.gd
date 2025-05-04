# res://Scripts/ItemPickup.gd
extends Area2D
class_name ItemPickup

@export var item_resource: ItemData   # drag-and-drop your .tres here
@export var amount: int = 1

func _ready() -> void:
	print("ItemPickup: ready, item=", item_resource, "amount=", amount)
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	if area is PlayerMovement and item_resource:
		Inv.add_item(item_resource.id, amount)
		print("ItemPickup: picked up %d x %s" % [amount, item_resource.id])
		queue_free()
