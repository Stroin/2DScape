# res://Scripts/CraftingUI.gd

extends Control
class_name CraftingUI

@export var pathfinding_controller_path: NodePath

# --- node refs ----------------------------------------------------------
@onready var pc           : PathfindingController = get_node(pathfinding_controller_path) as PathfindingController
@onready var player       : PlayerMovement        = pc.player
@onready var panel        : Panel                 = $CanvasLayer/Panel
@onready var list_vbox    : VBoxContainer         = $CanvasLayer/Panel/VBoxContainer
@onready var recipe_label : Label                 = $CanvasLayer/Panel/RecipeLabel
@onready var craft_button : Button                = $CanvasLayer/Panel/CraftButton
@onready var close_button : Button                = $CanvasLayer/Panel/CloseButton

var selected_id: String = ""

func _ready() -> void:
	panel.visible = false
	pc.connect("interact_requested", Callable(self, "_on_interact"))
	craft_button.connect("pressed", Callable(self, "_on_craft_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	if player:
		player.connect("movement_started", Callable(self, "_on_player_move_away"))
	else:
		push_warning("CraftingUI: player not found for movement_started")

func _on_interact(interactable_type: String, cell: Vector2i) -> void:
	if interactable_type != "crafting_table":
		return
	panel.visible = true
	pc.set_process_input(false)
	_refresh_list()

func _on_close_pressed() -> void:
	panel.visible = false
	pc.set_process_input(true)

func _on_player_move_away() -> void:
	panel.visible = false
	pc.set_process_input(true)

func _refresh_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()
	for tool_data in ToolManager._instance.tools:
		var btn = Button.new()
		btn.text = tool_data.display_name
		btn.name = tool_data.id
		list_vbox.add_child(btn)
		var cb = Callable(self, "_on_select_craft").bind(tool_data.id)
		btn.connect("pressed", cb)

func _on_select_craft(tool_id: String) -> void:
	selected_id = tool_id
	var stats  = ToolManager._instance.get_tool_stats(tool_id)
	var recipe = stats["recipe"]
	var txt = "Recipe for %s:\n" % stats["display_name"]
	for item_id in recipe.keys():
		var ing = IngredientManager.get_ingredient(item_id)
		var name: String = ""
		if ing != null:
			name = ing.display_name
		else:
			name = item_id
		txt += "%s: %d\n" % [name, recipe[item_id]]
	recipe_label.text = txt

func _on_craft_pressed() -> void:
	if selected_id == "":
		return
	if ToolManager._instance.craft(selected_id):
		panel.visible = false
		pc.set_process_input(true)
	else:
		recipe_label.text = "Cannot craft %s: missing ingredients" % selected_id
