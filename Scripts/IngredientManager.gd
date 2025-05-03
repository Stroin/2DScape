# res://Scripts/IngredientManager.gd

extends Node
class_name IngredientManager

# Folder path containing your IngredientData .tres files
@export var ingredients_folder: String = "res://Prefabs/Ingredients/"
# Loaded list of IngredientData resources
var ingredients: Array[IngredientData] = []

# singleton instance
static var _instance: IngredientManager

func _ready() -> void:
	IngredientManager._instance = self
	_load_ingredients()

func _load_ingredients() -> void:
	var dir = DirAccess.open(ingredients_folder)
	if dir == null:
		push_error("IngredientManager: could not open folder %s" % ingredients_folder)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".tres"):
			var path = "%s/%s" % [ingredients_folder, file_name]
			var res = load(path)
			if res and res is IngredientData:
				ingredients.append(res)
			else:
				push_warning("IngredientManager: resource at %s is not IngredientData" % path)
		file_name = dir.get_next()
	dir.list_dir_end()

# Lookup by id
static func get_ingredient(id: String) -> IngredientData:
	if IngredientManager._instance == null:
		push_error("IngredientManager not initialized!")
		return null
	for ing in IngredientManager._instance.ingredients:
		if ing.id == id:
			return ing
	return null

# Return all known ingredient IDs (for iterating, UIs, etc.)
static func get_all_ids() -> Array:
	if IngredientManager._instance == null:
		return []
	var ids: Array = []
	for ing in IngredientManager._instance.ingredients:
		ids.append(ing.id)
	return ids
