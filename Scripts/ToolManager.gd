# res://Scripts/ToolManager.gd
extends Node
class_name ToolManager

# Fired when a tool is successfully crafted
signal tool_crafted(tool_id: String)

# —————————————————————————————————————————————————————————————————————————————
# Your tool definitions: for each tool_id, configure:
#  - display_name : String
#  - any stats you want (damage, durability, etc.)
#  - recipe       : Dictionary[item_id: String] → count (int)
var tools: Dictionary = {
	"axe": {
		"display_name": "Axe",
		"damage": 2,
		"durability": 100,
		"recipe": {"wood": 3, "stone": 1},
	},
	"pickaxe": {
		"display_name": "Pickaxe",
		"damage": 1,
		"durability": 100,
		"recipe": {"wood": 2, "stone": 2},
	},
	# add more tools here...
}

func _ready() -> void:
	# nothing needed here right now; this just lives at /root/ToolManager
	pass

# Returns the full Dictionary of stats/recipe for a given tool_id,
# or an empty Dictionary (and warning) if not found.
func get_tool_stats(tool_id: String) -> Dictionary:
	if tools.has(tool_id):
		return tools[tool_id]
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
#  - checks can_craft()
#  - removes ingredients from Inv
#  - adds the crafted tool into Inv
#  - emits tool_crafted()
# Returns true on success, false otherwise.
func craft(tool_id: String) -> bool:
	if not can_craft(tool_id):
		push_warning("ToolManager: Cannot craft '%s' – missing ingredients." % tool_id)
		return false

	var recipe: Dictionary = tools[tool_id]["recipe"]
	# consume ingredients
	for item_id in recipe.keys():
		Inv.remove_item(item_id, recipe[item_id])
	# give the tool
	Inv.add_item(tool_id, 1)
	emit_signal("tool_crafted", tool_id)
	print("ToolManager: crafted 1 x %s" % tool_id)
	return true
