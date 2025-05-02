# res://Scripts/ResourceData.gd

extends Resource
class_name ResourceData

# A unique key matching the TileData.custom_data["resource_type"]
@export var id: String

# Human-friendly name
@export var display_name: String

# How long it takes to gather (seconds)
@export var gather_time: float = 1.0

# PackedScene to instance when the resource is gathered (e.g. wood log, ore chunk)
@export var drop_scene: PackedScene

# What inventory item this resource yields (must match your Inventory key)
@export var drop_item_id: String = ""

# How many of that item to give the player
@export var drop_amount: int = 1

# Time in seconds before this resource reappears
@export var respawn_time: float = 30.0

# XP to award when gathered
@export var xp_reward: float = 1.0

# Which skill to apply that XP to (e.g. "woodcutting", "mining")
@export var skill: String = ""

# Which tool is required to gather this resource (match a ToolData.id)
@export var required_tool: String = ""

# Minimum player level in that skill required to gather
@export var required_level: int = 0

# how much tool durability this resource costs
@export var tool_durability_cost: int = 1

# Atlas coords (in your TileSet’s atlas) to swap this resource’s tile to when gathered
@export var atlas_coords: Vector2i = Vector2i(0, 0)
