# res://Scripts/InventoryUI.gd

extends CanvasLayer
class_name InventoryUI

# Automatically finds your global inventory autoload (named "Inv")
@onready var label: Label = $Label

func _process(delta: float) -> void:
	# pull the current stacks every frame and rebuild the text
	var stacks = Inv.get_stacks()
	var txt := "Inventory:\n"
	for item_id in stacks.keys():
		for s in stacks[item_id]:
			txt += "%s: %d\n" % [item_id, s]
	label.text = txt
