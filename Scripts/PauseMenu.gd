extends Control

func _ready():
	# — Put this node in a dedicated CanvasLayer so it always stays in viewport space —
	call_deferred("_attach_to_canvas_layer")

	visible = false

	# — Make this Control cover the whole screen and draw above everything —
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = 0
	offset_top    = 0
	offset_right  = 0
	offset_bottom = 0
	z_index       = 100

	# — Still process input when paused —
	process_mode = Node.PROCESS_MODE_ALWAYS

	# — Dark overlay —
	var overlay = $Overlay as ColorRect
	overlay.process_mode   = Node.PROCESS_MODE_ALWAYS
	overlay.anchor_left    = 0.0
	overlay.anchor_top     = 0.0
	overlay.anchor_right   = 1.0
	overlay.anchor_bottom  = 1.0
	overlay.offset_left    = 0
	overlay.offset_top     = 0
	overlay.offset_right   = 0
	overlay.offset_bottom  = 0
	overlay.color          = Color(0, 0, 0, 0.5)
	overlay.z_index        = 101

	# — Center and style pause menu panel —
	var menu = $Menu as PanelContainer
	menu.process_mode            = Node.PROCESS_MODE_ALWAYS
	menu.anchor_left             = 0.25
	menu.anchor_top              = 0.25
	menu.anchor_right            = 0.75
	menu.anchor_bottom           = 0.75
	menu.offset_left             = 0
	menu.offset_top              = 0
	menu.offset_right            = 0
	menu.offset_bottom           = 0
	menu.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	menu.size_flags_vertical     = Control.SIZE_EXPAND_FILL
	menu.z_index                 = 102

	# — Wire up buttons —
	$Menu/VBoxContainer/ResumeButton.pressed.connect(_on_ResumeButton_pressed)
	$Menu/VBoxContainer/OptionsButton.pressed.connect(_on_OptionsButton_pressed)
	$Menu/VBoxContainer/QuitButton.pressed.connect(_on_QuitButton_pressed)

	# — Options panel setup —
	var opts = $Menu/VBoxContainer/OptionsPanel
	opts.process_mode                            = Node.PROCESS_MODE_ALWAYS
	opts.visible                                 = false
	var opts_box = opts.get_node("VBoxContainer")
	opts_box.size_flags_horizontal               = Control.SIZE_EXPAND_FILL
	var vol_slider = opts_box.get_node("VolumeSlider")
	vol_slider.value = clamp(
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) + 80, 0, 80)
	vol_slider.value_changed.connect(_on_VolumeSlider_value_changed)
	opts_box.get_node("BackButton").pressed.connect(_on_BackButton_pressed)


func _attach_to_canvas_layer():
	var parent_layer := get_parent()
	if parent_layer is CanvasLayer:
		return
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	get_tree().root.add_child(ui_layer)
	parent_layer.remove_child(self)
	ui_layer.add_child(self)


func _input(event):
	# Ignore ESC while the Main-menu scene is active
	var cs := get_tree().current_scene
	if cs and cs.scene_file_path.ends_with("MainMenu.tscn"):
		if event.is_action_pressed("ui_cancel"):
			accept_event()   # swallow ESC on the main menu
		return

	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_ResumeButton_pressed()
		else:
			_show_pause_menu()


func _show_pause_menu():
	get_tree().paused = true
	visible = true
	$Menu/VBoxContainer/OptionsPanel.visible = false
	$Menu/VBoxContainer/ResumeButton.visible = true
	$Menu/VBoxContainer/OptionsButton.visible = true
	$Menu/VBoxContainer/QuitButton.visible    = true


func _on_ResumeButton_pressed():
	$Menu/VBoxContainer/OptionsPanel.visible = false
	$Menu/VBoxContainer/ResumeButton.visible = true
	$Menu/VBoxContainer/OptionsButton.visible = true
	$Menu/VBoxContainer/QuitButton.visible    = true
	get_tree().paused = false
	visible = false


func _on_QuitButton_pressed():
	SaveGam.save_state()
	$Menu/VBoxContainer/OptionsPanel.visible = false
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _on_OptionsButton_pressed():
	$Menu/VBoxContainer/ResumeButton.visible = false
	$Menu/VBoxContainer/OptionsButton.visible = false
	$Menu/VBoxContainer/QuitButton.visible    = false
	$Menu/VBoxContainer/OptionsPanel.visible = true


func _on_BackButton_pressed():
	$Menu/VBoxContainer/OptionsPanel.visible = false
	$Menu/VBoxContainer/ResumeButton.visible = true
	$Menu/VBoxContainer/OptionsButton.visible = true
	$Menu/VBoxContainer/QuitButton.visible    = true


func _on_VolumeSlider_value_changed(value):
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, value - 80)
