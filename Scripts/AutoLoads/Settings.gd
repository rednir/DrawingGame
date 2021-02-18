extends Node


const GAME_NAME = "Drawing Game"
const GAME_VERSION = "v0.5"
const REPO_PATH = "rednir/DrawingGame"
const MIN_NAME_LENGTH = 2
const MIN_WINDOW_SIZE = Vector2(512, 300)
const CONFIG_PATH = "user://config.ini"


var config_file = ConfigFile.new()
var config = {
	display = {
		width = 1024,
		height = 600,
		is_fullscreen = false
	},
	audio = {
		master_volume = -10,
	},
	game = {
		last_name = "",
		drawing_fps = 50
	}
}




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
			config[section][key] = config_file.get_value(section, key, config[section][key])

	return OK




func save_config():
	for section in config.keys():
		for key in config[section].keys():
			config_file.set_value(section, key, config[section][key])

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
	OS.window_size = Vector2(config.display.width, config.display.height)
	OS.window_fullscreen = config.display.is_fullscreen




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
