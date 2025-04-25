# res://Scripts/IngredientData.gd
extends Resource
class_name IngredientData

# A unique key used in inventory, recipes, etc.
@export var id: String
# What shows up in UIs
@export var display_name: String
# (optional) icon to represent it
@export var icon: Texture2D
# (optional) description or tooltip
@export var description: String = ""
# How many can stack in one slot
@export var max_stack: int = 99
