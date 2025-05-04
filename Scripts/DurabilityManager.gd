extends Node
class_name DurabilityManager

# Tracks current durability per item instance (by item_id)
var current: Dictionary = {}

# Call whenever you want to drain durability on a tool.
func reduce_durability(item_id: String, cost: int) -> void:
	# initialize if first time this session
	if not current.has(item_id):
		var def = ItemManager.get_item(item_id)
		if def:
			current[item_id] = def.durability
		else:
			push_warning("DurabilityManager: Unknown item '%s'" % item_id)
			return

	current[item_id] -= cost
	print("DurabilityManager: %s durability now %d" % [item_id, current[item_id]])

	# if it broke, remove one from inventory
	if current[item_id] <= 0:
		Inv.remove_item(item_id, 1)
		current.erase(item_id)
		print("DurabilityManager: %s broke and was removed" % item_id)
