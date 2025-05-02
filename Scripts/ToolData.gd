# res://Scripts/ToolData.gd

extends Resource
class_name ToolData

# Unique identifier matching your inventory key (e.g. "axe", "pickaxe")
@export var id: String

# Human-friendly name
@export var display_name: String

# Damage dealt by this tool
@export var damage: int = 1

# Maximum durability
@export var durability: int = 100

# Crafting recipe: item_id → count
@export var recipe: Dictionary = {}
