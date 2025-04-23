# res://Scripts/ResourceManager.gd
extends Node
class_name ResourceManager

# Populate this in the inspector with your ResourceData .tres files
@export var resources: Array[ResourceData] = []

# singleton instance
static var _instance: ResourceManager

func _ready() -> void:
	ResourceManager._instance = self

static func get_resource(id: String) -> ResourceData:
	if ResourceManager._instance == null:
		push_error("ResourceManager not initialized yet!")
		return null
	for r in ResourceManager._instance.resources:
		if r.id == id:
			return r
	return null
