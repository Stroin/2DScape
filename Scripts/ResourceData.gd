extends Resource
class_name ResourceData

# Unique key matching the TileData.custom_data["resource_type"]
@export var id: String

# Human-friendly name
@export var display_name: String

# How long it takes to gather (seconds)
@export var gather_time: float = 1.0

# What inventory item this resource yields
@export var drop_item: ItemData
@export var drop_amount: int     = 1

# Time in seconds before this resource reappears
@export var respawn_time: float  = 30.0

# XP to award when gathered
@export var xp_reward: float     = 1.0
@export var skill: String        = ""   # e.g. "mining", "woodcutting"

# Minimum tool required (drag-and-drop your ItemData .tres here)
@export var required_tool: ItemData

# Minimum player level in that skill required to gather
@export var required_level: int   = 0
@export var tool_durability_cost: int = 1

# Atlas coords (in your TileSet’s atlas) to swap this resource’s tile to when gathered
@export var atlas_coords: Vector2i = Vector2i(0, 0)
