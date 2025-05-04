extends Control
class_name InventoryUI

# Automatically finds your global inventory autoload (named "Inv")
@onready var label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/Label

func _process(_delta: float) -> void:
	var stacks = Inv.get_stacks()
	var txt = "Inventory:\n"
	for item_id in stacks.keys():
		var data = ItemManager.get_item(item_id)
		var name = data.display_name if data else item_id
		for c in stacks[item_id]:
			txt += "%s: %d\n" % [name, c]
	label.text = txt
