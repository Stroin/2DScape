# res://Scripts/Resource.gd

extends Resource
class_name ResourceData

# A unique key matching the TileData.custom_data["resource_type"]
@export var id: String

# Human-friendly name
@export var display_name: String

# How long it takes to gather (seconds)
@export var gather_time: float = 1.0

# PackedScene to instance when the resource is gathered
@export var drop_scene: PackedScene

# —————————————————————————————————————————————————————————————————————————————

# What inventory item this resource yields
@export var drop_item_id: String = ""
@export var drop_amount: int = 1

# Time in seconds before this resource reappears
@export var respawn_time: float = 30.0

# XP to award when gathered
@export var xp_reward: float = 1.0
@export var skill: String = ""

# Atlas coords to swap this resource’s tile to when gathered
@export var atlas_coords: Vector2i = Vector2i(0, 0)
