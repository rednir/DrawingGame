extends Node


const GAME_NAME = "Drawing Game"
const GAME_VERSION = "v0.5"
const REPO_PATH = "rednir/DrawingGame"
const MIN_NAME_LENGTH = 2
const MIN_WINDOW_SIZE = Vector2(512, 300)
const CONFIG_PATH = "user://config.ini"

# keys called "tab_data" hold constant data for the parent tab, not stored in the config file or visible in settings menu
const DEFAULT_CONFIG = {
	display = {
		tab_data = {
			display_name = "Display",
			description = "",
			type = "Tab",
			value = null
		},
		resolution = {
			display_name = "",
			description = "",
			type = null,
			value = Vector2(1024, 600)
		},
		possible_resolutions = {
			display_name = "Resolution",
			description = "Set the size of the window in pixels.",
			type = "MenuButton",
			value = [Vector2(819, 480), Vector2(1024, 600), Vector2(1228, 720), Vector2(1311, 768), Vector2(1536, 900), Vector2(1843, 1080)]
		},
		is_fullscreen = {
			display_name = "Fullscreen",
			description = "Toggle whether the window takes up the entire screen.",
			type = "CheckBox",
			value = false
		}
	},
	audio = {
		tab_data = {
			display_name = "Audio",
			description = "",
			type = "Tab",
			value = null
		},
		master_volume = {
			display_name = "Master Volume",
			description = "Controls volume of all sounds.",
			type = "HSlider",
			value = -10,
			range_prop = {
				min_value = -100,
				max_value = 0,
				step = 8
			}
		},
	},
	game = {
		tab_data = {
			display_name = "Game",
			description = "",
			type = "Tab",
			value = null
		},
		last_name = {
			display_name = "",
			description = "",
			type = null,
			value = ""
		},
		drawing_fps = {
			display_name = "Drawing Framerate",
			description = "Controls the number of times per second a line is drawn.\nTry adjust this if your drawings look polygonal.",
			type = "SpinBox",
			value = 50,
			range_prop = {
				min_value = 10,
				max_value = 60,
				step = 1
			}
		}
	},
	misc = {
		tab_data = {
			display_name = "Misc",
			description = "",
			type = "Tab",
			value = null
		},
		reset = {
			display_name = "Reset Settings",
			description = "Changes all settings to their original state.",
			type = "Button",
			value = null
		}
	}
}

var config = DEFAULT_CONFIG.duplicate(true)
var config_file = ConfigFile.new()



func _ready():
	OS.min_window_size = MIN_WINDOW_SIZE
	OS.set_window_title("%s %s" % [GAME_NAME, GAME_VERSION])
	
	load_config()
	update_game_values_with_config()
	check_if_latest_release()




func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_config()




func load_config():
	if config_file.load(CONFIG_PATH) != OK:
		if create_config_file() == OK:
			if config_file.load(CONFIG_PATH) != OK:
				Events.emit_signal("info", "Could not load the config file\nThe game may not have sufficient privileges.")
				return ERR_FILE_CANT_READ
		else:
			Events.emit_signal("info", "Could not create a config file.\nThe game may not have sufficient privileges.")
			return ERR_FILE_CANT_OPEN
		
	for section in config.keys():
		for key in config[section].keys():
			if config[section][key].value == null:
				# settings that have default value null aren't stored (used for tab display names)
				continue
			config[section][key].value = config_file.get_value(section, key, config[section][key].value)

	return OK




func save_config():
	for section in config.keys():
		for key in config[section].keys():
			if config[section][key].value == null:
				# settings that have default value null aren't stored (used for tab display names)
				continue
			config_file.set_value(section, key, config[section][key].value)

	if config_file.save(CONFIG_PATH) != OK:
		Events.emit_signal("info", "Could not save the config file\nThe game may not have sufficient privileges.")
		return ERR_FILE_CANT_WRITE
	else:
		return OK




func create_config_file():
	var file = File.new()
	var err = file.open(CONFIG_PATH, File.WRITE)
	file.close()
	return err




func update_game_values_with_config():
	# dont adjust window size if fullscreen is on
	if !config.display.is_fullscreen.value:
		OS.window_size = config.display.resolution.value

	OS.window_fullscreen = config.display.is_fullscreen.value
	Engine.iterations_per_second = config.game.drawing_fps.value
	




func reset_config():
	config = DEFAULT_CONFIG.duplicate(true)
	save_config()
	update_game_values_with_config()
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
	




func check_if_latest_release():
	var github_http_req = HTTPRequest.new()
	Engine.get_main_loop().current_scene.add_child(github_http_req)
	github_http_req.connect("request_completed", self, "on_github_req_completed")
	github_http_req.request("https://api.github.com/repos/%s/releases/latest" % REPO_PATH)




func on_github_req_completed(_result, response_code, _headers, body):
	if response_code != HTTPClient.RESPONSE_OK:
		return

	var latest_release = JSON.parse(body.get_string_from_utf8()).result
	
	var current_game_version_no = float(GAME_VERSION.lstrip("v"))
	var latest_game_version_no = float(latest_release.tag_name.lstrip("v"))

	if latest_game_version_no > current_game_version_no:
		Events.emit_signal("question", "You are not on the latest release.\nDownload %s?" % latest_release.tag_name)
		Engine.get_main_loop().current_scene.get_node("ConfirmationDialog").get_ok().connect("pressed", self, "on_download_latest_confirmed")




func on_download_latest_confirmed():
	OS.shell_open("https://github.com/%s/releases/latest" % Settings.REPO_PATH)
