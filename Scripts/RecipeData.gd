# res://Scripts/RecipeData.gd
extends Resource
class_name RecipeData

# What you get: drag‐and‐drop the ItemData resource
@export var output_item: ItemData
@export var output_count: int = 1

# What you need: an array of CraftIngredient resources
@export var inputs: Array[CraftIngredient] = []

# Which station this uses: must match your TileMap.custom_data.interactable_type
@export var station: String = "crafting_table"

# Skill requirements & rewards
@export var min_skill: String = ""
@export var min_level: int = 1
@export var xp_reward: float = 0.0
@export var skill_reward: String = ""
