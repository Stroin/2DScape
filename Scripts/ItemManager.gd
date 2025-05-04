extends Node
class_name ItemManager

@export var items_folder: String = "res://Prefabs/Items/"
var items: Array[ItemData] = []
static var _instance: ItemManager

signal items_loaded

func _ready() -> void:
	ItemManager._instance = self
	_load_items()
	emit_signal("items_loaded")

func _load_items() -> void:
	_scan_dir(items_folder)

func _scan_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_error("ItemManager: could not open folder %s" % path)
		return

	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var full_path = "%s/%s" % [path, name]
			if dir.current_is_dir():
				_scan_dir(full_path)
			elif name.to_lower().ends_with(".tres"):
				var res = load(full_path)
				if res and res is ItemData:
					items.append(res)
				else:
					push_warning("ItemManager: %s is not ItemData" % full_path)
		name = dir.get_next()
	dir.list_dir_end()

static func get_item(id: String) -> ItemData:
	if _instance == null:
		push_error("ItemManager not ready!")
		return null
	for it in _instance.items:
		if it.id == id:
			return it
	return null

static func get_all_ids() -> Array:
	if _instance == null:
		return []
	return _instance.items.map(func(i): return i.id)
