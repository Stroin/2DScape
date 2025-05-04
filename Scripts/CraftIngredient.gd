# res://Scripts/CraftIngredient.gd
extends Resource
class_name CraftIngredient

# An ItemData plus how many are required
@export var item: ItemData
@export var count: int = 1
