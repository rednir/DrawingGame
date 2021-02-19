extends Control


onready var settings_container = $CenterContainer/SettingsContainer


func _ready():
	$ButtonBack.connect("pressed", self, "on_button_back_pressed")
	generate_settings_menu()



func generate_settings_menu():
	for child in settings_container.get_children():
		child.queue_free()

	for section_name in Settings.config.keys():
		var tab = VBoxContainer.new()
		tab.name = Settings.config[section_name].tab_data.display_name
		settings_container.add_child(tab)
		for key_name in Settings.config[section_name].keys():
			var current_key = Settings.config[section_name][key_name]
			if current_key.display_name == "":
				# hide settings with no display_name from the user
				continue

			var key_container = HBoxContainer.new()
			var label = Label.new()
			var item
			
			# TODO: fix repeated code
			# decide what node to use based on the type index
			match current_key.type:
				"CheckBox":
					item = CheckBox.new()
					item.text = current_key.display_name
					item.pressed = current_key.value
					item.connect("toggled", self, "on_setting_changed", [section_name, key_name])
				"LineEdit":
					item = LineEdit.new()
					item.text = str(current_key.value)
					item.connect("text_changed", self, "on_setting_changed", [section_name, key_name])
					key_container.add_child(label)
				"SpinBox":
					item = SpinBox.new()
					item.max_value = current_key.range_prop.max_value
					item.min_value = current_key.range_prop.min_value
					item.step = current_key.range_prop.step
					item.value = int(current_key.value)
					item.connect("value_changed", self, "on_setting_changed", [section_name, key_name])
					key_container.add_child(label)
				"MenuButton":
					item = MenuButton.new()
					item.get_popup().connect("index_pressed", self, "on_setting_changed", [section_name, key_name])
					if key_name == "possible_resolutions":
						for option in current_key.value:
							item.get_popup().add_item("%dx%d" % [option.x, option.y])
						item.text = "%dx%d" % [Settings.config.display.resolution.value.x, Settings.config.display.resolution.value.y]
					else:
						# do some generic thing if its an array but not res settings
						pass
					item.flat = false
					key_container.add_child(label)
				"Button":
					item = Button.new()
					item.text = "Confirm"
					item.connect("pressed", self, "on_setting_changed", [null, section_name, key_name])
					key_container.add_child(label)
				"HSlider":
					item = HSlider.new()
					item.max_value = current_key.range_prop.max_value
					item.min_value = current_key.range_prop.min_value
					item.step = current_key.range_prop.step
					item.value = current_key.value
					item.connect("value_changed", self, "on_setting_changed", [section_name, key_name])
					key_container.add_child(label)

			if item == null:
				continue

			key_container.name = key_name + "_container"
			item.name = key_name
			
			label.text = current_key.display_name
			label.hint_tooltip = current_key.description
			item.hint_tooltip = current_key.description

			label.size_flags_horizontal = SIZE_EXPAND_FILL
			item.size_flags_horizontal = SIZE_EXPAND_FILL

			tab.add_child(key_container)
			key_container.add_child(item)




func on_button_back_pressed():
	self.queue_free()




func on_setting_changed(new_value, section_name, key_name):
	var key_to_change = Settings.config[section_name][key_name]

	if key_name == "possible_resolutions":
		# override generic assignment to find out value from index & update MenuButton text
		Settings.config.display.resolution.value = Settings.config.display.possible_resolutions.value[new_value]
		get_node("CenterContainer/SettingsContainer/%s/possible_resolutions_container/possible_resolutions" % Settings.config.display.tab_data.display_name).text = "%dx%d" % [Settings.config.display.resolution.value.x, Settings.config.display.resolution.value.y]
	
	elif key_name == "reset":
		Events.emit_signal("question", "Reset all settings to their original state? This cannot be undone.")
		Engine.get_main_loop().current_scene.get_node("ConfirmationDialog").get_ok().connect("pressed", Settings, "reset_config")
		return
	
	else:
		# check if the value should be stored as an int
		if (int(new_value) != 0 or str(new_value) == "0") and typeof(new_value) != TYPE_BOOL:
			key_to_change.value = int(new_value)
		else:
			key_to_change.value = new_value

	if key_name == "master_volume":
		Events.play_sound("volumebar")

	Settings.update_game_values_with_config()
	Settings.save_config()
