# res://Scripts/Inventory.gd
extends Node
class_name Inventory

# maximum distinct slots before we warn+reject new items
@export var max_slots: int = 20

# mapping from item_id to quantity
var items: Dictionary = {}

func add_item(item_id: String, count: int = 1) -> void:
	# look up ingredient data to get its stack limit
	var ing: IngredientData = IngredientManager.get_ingredient(item_id)
	var cap: int
	if ing != null:
		cap = ing.max_stack
	else:
		cap = count

	if items.has(item_id):
		var current: int = items[item_id]
		if current >= cap:
			push_warning("%s stack is already at its max (%d)" % [item_id, cap])
			return
		var new_total: int = current + count
		if new_total > cap:
			items[item_id] = cap
			push_warning("Only added %d of %s to reach max stack (%d)" % [cap - current, item_id, cap])
		else:
			items[item_id] = new_total
	else:
		# new slot
		if items.size() >= max_slots:
			push_warning("Inventory full! Cannot add new item %s" % item_id)
			return
		if count > cap:
			items[item_id] = cap
			push_warning("Only added %d of %s to reach max stack (%d)" % [cap, item_id, cap])
		else:
			items[item_id] = count

	print("Inventory: %d x %s (/%d)" % [items[item_id], item_id, cap])

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
