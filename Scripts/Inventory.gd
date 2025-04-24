# res://Scripts/Inventory.gd
extends Node
class_name Inventory

# maximum distinct slots before we warn+reject new items
@export var max_slots: int = 20

# mapping from item_id to quantity
var items: Dictionary = {}

func add_item(item_id: String, count: int = 1) -> void:
	if items.has(item_id):
		items[item_id] += count
	else:
		if items.size() >= max_slots:
			push_warning("Inventory full! Cannot add %s" % item_id)
			return
		items[item_id] = count
	print("Inventory: Added %d x %s" % [count, item_id])

func remove_item(item_id: String, count: int = 1) -> void:
	if not items.has(item_id):
		push_warning("Inventory: Attempt to remove nonexistent item %s" % item_id)
		return
	items[item_id] -= count
	if items[item_id] <= 0:
		items.erase(item_id)
	print("Inventory: Removed %d x %s" % [count, item_id])

func get_items() -> Dictionary:
	return items
