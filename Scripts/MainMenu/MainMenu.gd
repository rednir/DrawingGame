extends Control


const SettingsScene = preload("res://Scenes/SettingsMenu.tscn")
const LoadingIconScene = preload("res://Scenes/LoadingIcon.tscn")


onready var text_game_info = $TopBarContainer/TextGameInfo
onready var textbox_join = $MainButtonsContainer/JoinContainer/TextboxJoin
onready var textbox_username = $MainButtonsContainer/TextboxUsername
onready var main_buttons_animation_player = $MainButtonsContainer/MainButtonsAnimation
onready var loading_icon_instance = LoadingIconScene.instance()


var settings_instance



func _ready():
	VisualServer.set_default_clear_color(Color("2c2c2f"))

	$BottomBarContainer.visible = false

	$MainButtonsContainer/JoinContainer/ButtonJoin.connect("pressed", self, "on_button_join_pressed")
	$MainButtonsContainer/ButtonCreate.connect("pressed", self, "on_button_create_pressed")
	$BottomBarContainer/ButtonSettings.connect("pressed", self, "on_button_settings_pressed")
	$BottomBarContainer/ButtonGithub.connect("pressed", self, "on_button_github_pressed")
	$TopBarContainer/ButtonExit.connect("pressed", self, "on_button_exit_pressed")
	
	if Server.public_ip == null:
		Server.ip_http_req.connect("request_completed", self, "on_ip_got")
		self.add_child(loading_icon_instance)
	else:
		on_ip_got(null, null, null, null)

	text_game_info.bbcode_text = "%s %s" % [Settings.GAME_NAME, Settings.GAME_VERSION]
	textbox_username.text = Settings.config.game.last_name





func on_ip_got(_result, _response_code, _headers, _body):
	main_buttons_animation_player.play("in")
	if loading_icon_instance != null:		# might cause crashes in release build
		loading_icon_instance.get_node("AnimationPlayer").play("out")
	$BottomBarContainer.visible = true




func on_button_join_pressed():
	Settings.config.game.last_name = textbox_username.text

	main_buttons_transition("out")
	yield(main_buttons_animation_player, "animation_finished")

	var status_code = Client.try_join_server(textbox_join.text)
	if len(textbox_username.text) < Settings.MIN_NAME_LENGTH:
		Events.emit_signal("error", "Username is too short")
	else:
		if status_code != OK:
			Events.emit_signal("error", "Could not join the server (Code: %s)\nMake sure the IP address exists." % status_code)
		else:
			Client.this_player.name = textbox_username.text
			get_tree().change_scene("res://Scenes/Game.tscn")
			return

	main_buttons_transition("in")



		
func on_button_create_pressed():
	Settings.config.game.last_name = textbox_username.text
	
	main_buttons_transition("out")
	yield(main_buttons_animation_player, "animation_finished")

	var status_code = Server.try_create_server()
	if len(textbox_username.text) < Settings.MIN_NAME_LENGTH:
		Events.emit_signal("error", "Username is too short")
	else:
		if status_code != OK:
			Events.emit_signal("error", "Could not create a server (Code: %s)" % status_code)
			Server.server = null
		else:
			Client.this_player.name = textbox_username.text
			Client.try_join_server("localhost")
			get_tree().change_scene("res://Scenes/Game.tscn")
			return
		
	main_buttons_transition("in")




func on_button_settings_pressed():
	$BottomBarContainer.visible = false
	main_buttons_transition("out")
	yield(main_buttons_animation_player, "animation_finished")

	settings_instance = SettingsScene.instance()
	settings_instance.connect("back", self, "on_button_settings_back_pressed")
	self.add_child(settings_instance)




func on_button_settings_back_pressed():
	$BottomBarContainer.visible = true
	main_buttons_transition("in")
	settings_instance.queue_free()




func on_button_github_pressed():
	var code = OS.shell_open("https://github.com/%s" % Settings.REPO_PATH)
	if code != OK:
		Events.emit_signal("error", "Could not open page.")




func on_button_exit_pressed():
	$TopBarContainer/ButtonExit.disabled = true
	get_tree().quit()




func main_buttons_transition(anim):
	main_buttons_animation_player.play(anim)
	$MainButtonsContainer/JoinContainer/ButtonJoin.disabled = (anim == "out")
	$MainButtonsContainer/ButtonCreate.disabled = (anim == "out")
