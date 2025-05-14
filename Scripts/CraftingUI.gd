# res://Scripts/CraftingUI.gd
extends Control
class_name CraftingUI

@export var pathfinding_controller_path: NodePath

@onready var pc            = get_node(pathfinding_controller_path)
@onready var player        = pc.player
@onready var panel         = $CanvasLayer/Panel
@onready var list_vbox     = $CanvasLayer/Panel/ScrollContainer/VBoxContainer
@onready var details_label = $CanvasLayer/Panel/RecipeLabel
@onready var craft_button  = $CanvasLayer/Panel/CraftButton
@onready var close_button  = $CanvasLayer/Panel/CloseButton

var selected_recipe: RecipeData = null
var current_station: String     = ""

func _ready() -> void:
	panel.visible = false
	pc.connect("interact_requested", Callable(self, "_on_pc_interact"))
	craft_button.connect("pressed", Callable(self, "_on_craft_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	if player:
		player.connect("movement_started", Callable(self, "_on_player_move_away"))
	else:
		push_warning("CraftingUI: player not found")

func _on_pc_interact(interactable: Interactable, _cell: Vector2i) -> void:
	# only respond to crafting tables
	if interactable.interactable_type != "crafting_table":
		return
	current_station = interactable.interactable_type
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
	# clear old buttons
	for child in list_vbox.get_children():
		child.queue_free()
	# fetch, sort (craftable first, then name), and add one button per RecipeData
	var recipes = RecipeManager.get_recipes_for_station(current_station)
	recipes.sort_custom(Callable(self, "_compare_recipes"))
	for r in recipes:
		var btn = Button.new()
		btn.text = r.output_item.display_name
		btn.name = r.output_item.id
		# visually gray out uncraftable recipes, but keep them enabled
		if not RecipeManager.can_craft(r):
			btn.modulate = Color(0.5, 0.5, 0.5)
		list_vbox.add_child(btn)
		btn.connect("pressed", Callable(self, "_on_select").bind(r))

func _compare_recipes(a: RecipeData, b: RecipeData) -> bool:
	# craftable recipes first
	var can_a = RecipeManager.can_craft(a)
	var can_b = RecipeManager.can_craft(b)
	if can_a and not can_b:
		return true
	elif not can_a and can_b:
		return false
	# then alphabetical by display name
	return a.output_item.display_name < b.output_item.display_name

func _on_select(r: RecipeData) -> void:
	selected_recipe = r
	# header: output name & count
	var txt = "%s x%d\n\nRequires:\n" % [r.output_item.display_name, r.output_count]
	# list each ingredient
	for ci in r.inputs:
		txt += "%s: %d\n" % [ci.item.display_name, ci.count]
	# skill & XP
	if r.min_skill != "":
		txt += "\nNeed %s level %d\nGain %.1f XP" % [
			r.min_skill.capitalize(), r.min_level, r.xp_reward
		]
	details_label.text = txt

func _on_craft_pressed() -> void:
	if selected_recipe == null:
		return
	if RecipeManager.craft(selected_recipe):
		_on_close_pressed()
	else:
		details_label.text = "Cannot craft: check ingredients & skill"
