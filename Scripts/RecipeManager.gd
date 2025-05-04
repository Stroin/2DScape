# res://Scripts/RecipeManager.gd
extends Node
class_name RecipeManager

@export var recipes_folder: String = "res://Prefabs/Recipes/"
var recipes: Array[RecipeData] = []
static var _instance: RecipeManager

signal recipe_crafted(output_item: ItemData)

func _ready() -> void:
	RecipeManager._instance = self
	_load_recipes()

func _load_recipes() -> void:
	_scan_dir(recipes_folder)

func _scan_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_error("RecipeManager: could not open folder %s" % path)
		return
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var full = "%s/%s" % [path, name]
			if dir.current_is_dir():
				_scan_dir(full)
			elif name.to_lower().ends_with(".tres"):
				var res = load(full)
				if res and res is RecipeData:
					recipes.append(res)
				else:
					push_warning("RecipeManager: %s is not RecipeData" % full)
		name = dir.get_next()
	dir.list_dir_end()

static func get_recipes_for_station(st: String) -> Array:
	if _instance == null:
		return []
	return _instance.recipes.filter(func(r): return r.station == st)

static func get_recipe_by_output_item(item: ItemData) -> RecipeData:
	if _instance == null:
		return null
	for r in _instance.recipes:
		if r.output_item == item:
			return r
	return null

static func can_craft(r: RecipeData) -> bool:
	# skill check
	if r.min_skill != "" and Stats.get_level(r.min_skill) < r.min_level:
		return false
	# inventory check
	var have = Inv.get_items()
	for ci in r.inputs:
		if have.get(ci.item.id, 0) < ci.count:
			return false
	return true

static func craft(r: RecipeData) -> bool:
	if not can_craft(r):
		return false
	# consume ingredients
	for ci in r.inputs:
		Inv.remove_item(ci.item.id, ci.count)
	# give output
	Inv.add_item(r.output_item.id, r.output_count)
	# give XP
	if r.skill_reward != "":
		Stats.add_xp(r.skill_reward, r.xp_reward)
	_instance.emit_signal("recipe_crafted", r.output_item)
	return true
