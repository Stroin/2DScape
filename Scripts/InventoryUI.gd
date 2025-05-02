# res://Scripts/InventoryUI.gd

extends Control
class_name InventoryUI

# Automatically finds your global inventory autoload (named "Inv")
@onready var label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/Label

func _process(delta: float) -> void:
	# pull the current stacks every frame and rebuild the text
	var stacks = Inv.get_stacks()
	var txt := "Inventory:\n"
	for item_id in stacks.keys():
		# determine human-friendly name
		var display_name = item_id
		var ing = IngredientManager.get_ingredient(item_id)
		if ing != null:
			display_name = ing.display_name
		else:
			# check if it's a tool
			if ToolManager._instance != null:
				var stats = ToolManager._instance.get_tool_stats(item_id)
				if stats.has("display_name"):
					display_name = stats["display_name"]
		# list each stack separately
		for count in stacks[item_id]:
			txt += "%s: %d\n" % [display_name, count]
	label.text = txt
