# res://Scripts/ResourceManager.gd

extends Node
class_name ResourceManager

# Folder path containing your ResourceData .tres files
@export var resources_folder: String = "res://Prefabs/Resources/"
# Loaded list of ResourceData resources
var resources: Array[ResourceData] = []

# singleton instance
static var _instance: ResourceManager

func _ready() -> void:
	ResourceManager._instance = self
	_load_resources()

func _load_resources() -> void:
	var dir = DirAccess.open(resources_folder)
	if dir == null:
		push_error("ResourceManager: could not open folder %s" % resources_folder)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".tres"):
			var path = "%s/%s" % [resources_folder, file_name]
			var res = load(path)
			if res and res is ResourceData:
				resources.append(res)
			else:
				push_warning("ResourceManager: resource at %s is not ResourceData" % path)
		file_name = dir.get_next()
	dir.list_dir_end()

static func get_resource(id: String) -> ResourceData:
	if ResourceManager._instance == null:
		push_error("ResourceManager not initialized yet!")
		return null
	for r in ResourceManager._instance.resources:
		if r.id == id:
			return r
	return null
