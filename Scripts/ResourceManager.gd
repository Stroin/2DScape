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
	_scan_dir(resources_folder)

func _scan_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_error("ResourceManager: could not open folder %s" % path)
		return
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var full = "%s/%s" % [path, name]
			if dir.current_is_dir():
				_scan_dir(full)
			elif name.to_lower().ends_with(".tres"):
				var res = load(full)
				if res and res is ResourceData:
					resources.append(res)
				else:
					push_warning("ResourceManager: %s is not ResourceData" % full)
		name = dir.get_next()
	dir.list_dir_end()


static func get_resource(id: String) -> ResourceData:
	if ResourceManager._instance == null:
		push_error("ResourceManager not initialized yet!")
		return null
	for r in ResourceManager._instance.resources:
		if r.id == id:
			return r
	return null
