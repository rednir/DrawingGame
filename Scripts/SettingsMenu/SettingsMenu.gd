extends Control


onready var settings_container = $CenterContainer/SettingsContainer


signal back


func _ready():
	$ButtonBack.connect("pressed", self, "on_button_back_pressed")
	generate_settings_menu()



func generate_settings_menu():
	for child in settings_container.get_children():
		child.queue_free()

	for section in Settings.config.keys():
		var tab = VBoxContainer.new()
		tab.name = section.to_upper()
		settings_container.add_child(tab)
		for key in Settings.config[section].keys():
			var key_container = HBoxContainer.new()
			var label = Label.new()
			var item

			# decide what node to use based on the data type of the setting
			match typeof(Settings.config[section][key].value):
				TYPE_BOOL:
					item = CheckBox.new()
					item.text = key
					item.pressed = Settings.config[section][key].value
					item.connect("toggled", self, "on_setting_changed", [section, key])
				TYPE_INT:
					item = LineEdit.new()
					item.text = str(Settings.config[section][key].value)
					item.connect("text_changed", self, "on_setting_changed", [section, key])
					key_container.add_child(label)
				TYPE_STRING:
					item = LineEdit.new()
					item.text = Settings.config[section][key].value
					item.connect("text_changed", self, "on_setting_changed", [section, key])
					key_container.add_child(label)
				TYPE_ARRAY:
					item = MenuButton.new()
					item.get_popup().connect("index_pressed", self, "on_setting_changed", [section, key])
					if key == "possible_resolutions":
						for option in Settings.config[section][key].value:
							item.get_popup().add_item("%dx%d" % [option.x, option.y])
						item.text = "%dx%d" % [Settings.config.display.resolution.value.x, Settings.config.display.resolution.value.y]
					else:
						# do some generic thing if its an array but not res settings
						pass
					item.flat = false
					key_container.add_child(label)

			if item == null:
				continue
			
			label.text = key
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			item.size_flags_horizontal = SIZE_EXPAND_FILL

			tab.add_child(key_container)
			key_container.add_child(item)




func on_button_back_pressed():
	emit_signal("back")




func on_setting_changed(new_value, section, key):
	if key == "possible_resolutions":
		# override generic assignation to find out value from index / reload MenuButton text
		Settings.config.display.resolution.value = Settings.config.display.possible_resolutions.value[new_value]
		generate_settings_menu()
	else:
		# check if the value should be stored as an int
		if (int(new_value) != 0 or str(new_value) == "0") and typeof(new_value) != TYPE_BOOL:
			Settings.config[section][key].value = int(new_value)
		else:
			Settings.config[section][key].value = new_value

	Settings.update_game_values_with_config()
	Settings.save_config()
