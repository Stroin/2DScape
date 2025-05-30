extends Control

func _ready():
	# ——— start persistent BGM ———
	var root = get_tree().get_root()
	if not root.has_node("MusicPlayer"):
		var music_player = AudioStreamPlayer.new()
		music_player.name       = "MusicPlayer"
		#music_player.stream     = preload("res://audio/background.wav")
		music_player.bus        = "Master"
		music_player.volume_db  = 0
		root.call_deferred("add_child", music_player)
		music_player.call_deferred("play")
	# ——— end persistent BGM ———

	# center main menu
	$VBoxContainer.anchor_left   = 0.3
	$VBoxContainer.anchor_right  = 0.7
	$VBoxContainer.anchor_top    = 0.3
	$VBoxContainer.anchor_bottom = 0.7

	# have Play/Options/Quit buttons expand
	for btn in [$VBoxContainer/PlayButton, $VBoxContainer/OptionsButton, $VBoxContainer/QuitButton]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	$VBoxContainer/PlayButton.pressed.connect(_on_PlayButton_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_OptionsButton_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_QuitButton_pressed)

	# initialize options panel
	$OptionsPanel.visible = false

	# center options panel
	$OptionsPanel.anchor_left   = 0.25
	$OptionsPanel.anchor_right  = 0.75
	$OptionsPanel.anchor_top    = 0.25
	$OptionsPanel.anchor_bottom = 0.75

	# let options panel contents expand
	$OptionsPanel/VBoxContainer.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
	$OptionsPanel/VBoxContainer/BackButton.size_flags_horizontal   = Control.SIZE_EXPAND_FILL

	# configure volume slider: 0 = silent, 80 = full volume
	var slider = $OptionsPanel/VBoxContainer/VolumeSlider
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 80
	slider.step = 1
	var bus = AudioServer.get_bus_index("Master")
	slider.value = clamp(AudioServer.get_bus_volume_db(bus) + 80, 0, 80)

	$OptionsPanel/VBoxContainer/BackButton.pressed.connect(_on_BackButton_pressed)
	$OptionsPanel/VBoxContainer/VolumeSlider.value_changed.connect(_on_VolumeSlider_value_changed)



func _on_PlayButton_pressed():
	# 1) Try the SaveGam singleton (already loaded, even in-editor)
	var path := "res://Scenes/Tutorial_Part1.tscn"
	var sg   := SaveGam
	if sg and sg.last_scene != "":
		path = sg.last_scene
	else:
		# 2) Cold-start fallback: read the save file directly
		var cfg := ConfigFile.new()
		if cfg.load("user://save_game.cfg") == OK:
			if cfg.has_section_key("progress", "last_scene"):
				path = cfg.get_value("progress", "last_scene", path)
	get_tree().change_scene_to_file(path)


func _on_OptionsButton_pressed():
	$VBoxContainer.visible = false
	$OptionsPanel.visible  = true


func _on_QuitButton_pressed():
	SaveGam.save_state()
	get_tree().quit()


func _on_BackButton_pressed():
	$OptionsPanel.visible  = false
	$VBoxContainer.visible = true


func _on_VolumeSlider_value_changed(value):
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, value - 80)   # 0..80  ->  -80..0 dB
