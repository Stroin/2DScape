extends Node
class_name Inventory

# maximum distinct slots before we warn+reject new items
@export var max_slots: int = 20

# mapping from item_id to an Array of stack counts
var items: Dictionary = {}

func _get_total_stacks() -> int:
	var total: int = 0
	for stacks in items.values():
		total += stacks.size()
	return total

func add_item(item_id: String, count: int = 1) -> void:
	# look up ingredient data to get its stack limit
	var ing: IngredientData = IngredientManager.get_ingredient(item_id)
	var cap: int
	if ing != null:
		cap = ing.max_stack
	else:
		cap = count

	# get or create stack list for this item
	var stacks: Array
	if items.has(item_id):
		stacks = items[item_id]
	else:
		# new item introduces a slot (i.e. a new stack)
		if _get_total_stacks() >= max_slots:
			push_warning("Inventory full! Cannot add new item %s" % item_id)
			print("Inventory: Cannot add %s; inventory full" % item_id)
			return
		stacks = []

	var leftover: int = count

	# fill existing stacks
	for i in range(stacks.size()):
		if leftover <= 0:
			break
		var current: int = stacks[i]
		if current < cap:
			var space: int = cap - current
			var to_add: int
			if leftover < space:
				to_add = leftover
			else:
				to_add = space
			stacks[i] += to_add
			leftover -= to_add
			print("Inventory: Added %d x %s to existing stack (now %d/%d)" % [to_add, item_id, stacks[i], cap])

	# create new stacks for any leftover
	while leftover > 0:
		if _get_total_stacks() >= max_slots:
			push_warning("Inventory full! Cannot add new item %s" % item_id)
			print("Inventory: Cannot add %s; inventory full" % item_id)
			break
		var to_add2: int
		if leftover < cap:
			to_add2 = leftover
		else:
			to_add2 = cap
		stacks.append(to_add2)
		leftover -= to_add2
		print("Inventory: Added %d x %s in new stack" % [to_add2, item_id])

	items[item_id] = stacks

func remove_item(item_id: String, count: int = 1) -> void:
	if not items.has(item_id):
		push_warning("Inventory: Attempt to remove nonexistent item %s" % item_id)
		return
	var stacks: Array = items[item_id]
	var to_remove: int = count

	var i: int = 0
	while i < stacks.size() and to_remove > 0:
		var current: int = stacks[i]
		if current <= to_remove:
			to_remove -= current
			print("Inventory: Removed %d x %s from stack" % [current, item_id])
			stacks.remove_at(i)
			# next element shifts into index i
		else:
			stacks[i] = current - to_remove
			print("Inventory: Removed %d x %s from stack" % [to_remove, item_id])
			to_remove = 0
			i += 1

	if stacks.size() > 0:
		items[item_id] = stacks
	else:
		items.erase(item_id)

func get_items() -> Dictionary:
	# returns total count per item
	var totals: Dictionary = {}
	for item_id in items.keys():
		var sum: int = 0
		for s in items[item_id]:
			sum += s
		totals[item_id] = sum
	return totals

func get_stacks() -> Dictionary:
	# returns raw stack arrays for UI
	var result: Dictionary = {}
	for item_id in items.keys():
		result[item_id] = items[item_id].duplicate()
	return result
