# res://Scripts/InventoryUI.gd
extends CanvasLayer
class_name InventoryUI

# Automatically finds your global inventory autoload (named "Inv")
@onready var label: Label = $Label

func _process(delta: float) -> void:
	# pull the current items every frame and rebuild the text
	var items = Inv.get_items()
	var txt := "Inventory:\n"
	for item_id in items.keys():
		txt += "%s: %d\n" % [item_id, items[item_id]]
	label.text = txt
