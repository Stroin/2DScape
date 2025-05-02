# res://Scripts/StatsUI.gd

extends Control
class_name StatsUI

# grab the Label child
@onready var label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatsLabel

func _process(delta: float) -> void:
	# rebuild the stats text each frame
	var txt: String = "Skills:\n"
	for skill_name in Stats.skills.keys():
		var lvl: int    = Stats.get_level(skill_name)
		var xp_val: float   = Stats.get_xp(skill_name)
		var need: float     = Stats.get_xp_to_next(skill_name)
		txt += skill_name.capitalize() + ": Level " + str(lvl) + " (" + str(xp_val) + " / " + str(need) + " XP)\n"
	label.text = txt
