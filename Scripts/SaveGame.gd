extends Node
# class_name SaveGame   -- keep commented out so the autoload instance
						  # is available as the global variable “SaveGam”

const SAVE_PATH := "user://save_game.cfg"

var last_scene : String  = ""
var player_pos : Variant = null        # Vector2/3, null until something is saved

func _ready() -> void:
	_load_from_disk()
	print("SaveGame READY  | last_scene =", last_scene)     # DEBUG
	get_tree().connect("node_added", Callable(self, "_on_root_added"))

# ─────────────────────────────────────────────────────────────────────────────
# Saving
# ─────────────────────────────────────────────────────────────────────────────
func save_state() -> void:
	var current := get_tree().current_scene
	if not current:
		return
	if current.scene_file_path.ends_with("MainMenu.tscn"):
		return                                             # never save the main menu

	last_scene = current.scene_file_path
	var p := _find_player(current)
	if p:
		player_pos = (
			p.global_position if p.has_method("global_position") else p.position
		)

	print("SaveGame SAVE   |", last_scene, "| pos =", player_pos)  # DEBUG
	_save_to_disk()

# ─────────────────────────────────────────────────────────────────────────────
# Restoring
# ─────────────────────────────────────────────────────────────────────────────
func _on_root_added(node: Node) -> void:
	if node.get_parent() != get_tree().root:
		return                                            # not a scene root
	if node.scene_file_path != last_scene:
		return                                            # not the scene we saved

	print("SaveGame RESTORE queued for", node.scene_file_path)     # DEBUG
	call_deferred("_deferred_restore", node)

func _deferred_restore(scene_root: Node) -> void:
	await get_tree().process_frame                       # wait for first frame
	await get_tree().create_timer(0.05).timeout          # extra 50 ms buffer

	if player_pos == null:
		return
	var p := _find_player(scene_root)
	if not p:
		print("SaveGame: player NOT found – add to 'player' group")  # DEBUG
		return

	if p.has_method("global_position"):
		p.global_position = player_pos
	elif p.has_method("position"):
		p.position = player_pos

	print("SaveGame: player repositioned to", player_pos)          # DEBUG

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
func _find_player(node: Node) -> Node:
	if node.name in ["Player", "PlayerMovement"] or node.is_in_group("player"):
		return node
	for child in node.get_children():
		var hit := _find_player(child)
		if hit:
			return hit
	return null

# ─────────────────────────────────────────────────────────────────────────────
# Disk I/O
# ─────────────────────────────────────────────────────────────────────────────
func _save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress",  "last_scene", last_scene)
	cfg.set_value("player",    "pos",        player_pos)
	cfg.set_value("inventory", "items",      Inv.items)
	cfg.set_value("stats",     "skills",     Stats.skills)
	cfg.save(SAVE_PATH)

func _load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	last_scene = cfg.get_value("progress",  "last_scene", "")
	player_pos = cfg.get_value("player",    "pos",        null)

	var items  = cfg.get_value("inventory", "items",  null)
	if items != null:
		Inv.items = items.duplicate()

	var skills = cfg.get_value("stats", "skills", null)
	if skills != null:
		Stats.skills = skills.duplicate()
