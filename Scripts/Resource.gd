# res://Scripts/Resource.gd
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
