# res://Scripts/PlayerStats.gd

extends Node
class_name PlayerStats

# —————————————————————————————————————————————————————————————————————————————

# Maximum level any skill can reach
@export var max_level: int = 50

# Emitted whenever any skill levels up: (skill_name, new_level)
signal skill_leveled(skill_name: String, level: int)

# Internal data per skill
var skills: Dictionary = {
	"woodcutting": {"level": 1, "xp": 0.0, "xp_to_next": 10.0},
	"mining":       {"level": 1, "xp": 0.0, "xp_to_next": 10.0},
}

func add_xp(skill_name: String, amount: float = 1.0) -> void:
	if not skills.has(skill_name):
		push_warning("PlayerStats: Unknown skill '%s'" % skill_name)
		return

	var data = skills[skill_name]

	# if already at cap, do nothing
	if data.level >= max_level:
		print("PlayerStats: %s already at max level %d" % [skill_name, data.level])
		return

	data.xp += amount
	print("PlayerStats: %s +%.1f XP (%.1f/%.1f)" %
		[skill_name, amount, data.xp, data.xp_to_next])

	# level-up loop (in case a big XP drop pushes past multiple levels)
	while data.xp >= data.xp_to_next and data.level < max_level:
		data.xp -= data.xp_to_next
		data.level += 1
		data.xp_to_next *= 1.1  # increase next-level XP by 10%
		print("PlayerStats: %s reached level %d (next at %.1f XP)" %
			[skill_name, data.level, data.xp_to_next])
		emit_signal("skill_leveled", skill_name, data.level)

	# write back modified data
	skills[skill_name] = data

func get_level(skill_name: String) -> int:
	if skills.has(skill_name):
		return skills[skill_name].level
	return 0

func get_xp(skill_name: String) -> float:
	if skills.has(skill_name):
		return skills[skill_name].xp
	return 0.0

func get_xp_to_next(skill_name: String) -> float:
	if skills.has(skill_name):
		return skills[skill_name].xp_to_next
	return 0.0
