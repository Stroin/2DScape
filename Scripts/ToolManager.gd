# res://Scripts/ToolManager.gd

extends Node
class_name ToolManager

# Fired when a tool is successfully crafted
signal tool_crafted(tool_id: String)

# Populate in the inspector with your ToolData .tres files
@export var tools: Array[ToolData] = []

# Internal lookup: tool_id → ToolData
var tool_map: Dictionary = {}

# track current durability for each tool instance
var current_durabilities: Dictionary = {}

# singleton instance
static var _instance: ToolManager

func _ready() -> void:
	ToolManager._instance = self
	# build a quick lookup map
	for t in tools:
		tool_map[t.id] = t

# Returns a Dictionary of stats/recipe for tool_id, or empty + warning if not found.
func get_tool_stats(tool_id: String) -> Dictionary:
	if tool_map.has(tool_id):
		var td: ToolData = tool_map[tool_id]
		return {
			"display_name": td.display_name,
			"damage": td.damage,
			"durability": td.durability,
			"recipe": td.recipe
		}
	push_warning("ToolManager: Unknown tool '%s'" % tool_id)
	return {}

# Returns true if the player has enough ingredients in Inv to craft tool_id
func can_craft(tool_id: String) -> bool:
	var data: Dictionary = get_tool_stats(tool_id)
	if data.is_empty():
		return false
	var recipe: Dictionary = data["recipe"]
	for item_id in recipe.keys():
		var needed: int = recipe[item_id]
		var have = Inv.get_items().get(item_id, 0)
		if have < needed:
			return false
	return true

# Attempts to craft one of tool_id:
# - checks can_craft()
# - removes ingredients from Inv
# - adds the crafted tool into Inv
# - emits tool_crafted()
# Returns true on success, false otherwise.
func craft(tool_id: String) -> bool:
	if not can_craft(tool_id):
		push_warning("ToolManager: Cannot craft '%s' – missing ingredients." % tool_id)
		return false

	var recipe: Dictionary = tool_map[tool_id].recipe
	# consume ingredients
	for item_id in recipe.keys():
		Inv.remove_item(item_id, recipe[item_id])
	# give the tool
	Inv.add_item(tool_id, 1)
	emit_signal("tool_crafted", tool_id)
	print("ToolManager: crafted 1 x %s" % tool_id)
	return true

# Reduces durability on the given tool, breaking it if it hits zero.
func reduce_durability(tool_id: String, cost: int) -> void:
	if not tool_map.has(tool_id):
		push_warning("ToolManager: Unknown tool '%s'" % tool_id)
		return

	# initialize if first time
	if not current_durabilities.has(tool_id):
		current_durabilities[tool_id] = tool_map[tool_id].durability

	current_durabilities[tool_id] -= cost
	print("ToolManager: %s durability now %d" % [tool_id, current_durabilities[tool_id]])

	# if it broke, remove one from inventory
	if current_durabilities[tool_id] <= 0:
		Inv.remove_item(tool_id, 1)
		current_durabilities.erase(tool_id)
		print("ToolManager: %s broke and was removed" % tool_id)
