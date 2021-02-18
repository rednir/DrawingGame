extends Node


const GAME_NAME = "Drawing Game"
const GAME_VERSION = "v0.5"
const REPO_PATH = "rednir/DrawingGame"
const MIN_NAME_LENGTH = 2
const MIN_WINDOW_SIZE = Vector2(512, 300)



func _ready():
	OS.min_window_size = MIN_WINDOW_SIZE
	OS.set_window_title("%s %s" % [GAME_NAME, GAME_VERSION])

	check_if_latest_release()




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
