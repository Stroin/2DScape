extends Resource
class_name ItemData

enum Category { RAW, PROCESSED, TOOL, CONSUMABLE }

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var description: String = ""
@export var max_stack: int = 99
@export var category: Category = Category.RAW

# Tool fields (harmless if left at 0)
@export var damage: int = 0
@export var durability: int = 0
@export var tier: int = 0   # 1=wood,2=bronze,3=iron,...

# Consumable field (harmless if left blank)
@export var use_effect: String = ""
