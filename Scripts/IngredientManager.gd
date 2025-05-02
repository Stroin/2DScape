# res://Scripts/IngredientManager.gd

extends Node
class_name IngredientManager

# Populate in the Inspector with all your IngredientData .tres files
@export var ingredients: Array[IngredientData] = []

# singleton instance
static var _instance: IngredientManager

func _ready() -> void:
	IngredientManager._instance = self

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
