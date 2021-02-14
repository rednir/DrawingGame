extends Control


const GAME_NAME = "Drawing Game"
const GAME_VERSION = "0.4"


onready var text_game_info = $TextGameInfo
onready var textbox_join = $MainButtonsContainer/JoinContainer/TextboxJoin
onready var textbox_username = $MainButtonsContainer/TextboxUsername
onready var main_buttons_animation_player = $MainButtonsContainer/MainButtonsAnimation


const min_name_length = 2


func _ready():
	VisualServer.set_default_clear_color(Color("2c2c2f"))
	OS.set_window_title("%s v%s" % [GAME_NAME, GAME_VERSION])

	$MainButtonsContainer/JoinContainer/ButtonJoin.connect("pressed", self, "on_button_join_pressed")
	$MainButtonsContainer/ButtonCreate.connect("pressed", self, "on_button_create_pressed")

	text_game_info.bbcode_text = "%s v%s" % [GAME_NAME, GAME_VERSION]
	main_buttons_animation_player.play("in")






func on_button_join_pressed():
	disable_buttons(true)
	main_buttons_animation_player.play("out")
	yield(main_buttons_animation_player, "animation_finished")

	var status_code = Client.try_join_server(textbox_join.text)
	if len(textbox_username.text) < min_name_length:
		Events.emit_signal("error", "Username is too short")
	else:
		if status_code != OK:
			Events.emit_signal("error", "Could not join the server (Code: %s)\nMake sure the IP address exists." % status_code)
		else:
			Client.this_player.name = textbox_username.text
			get_tree().change_scene("res://Scenes/Game.tscn")
			return

	disable_buttons(false)
	main_buttons_animation_player.play("in")



		
func on_button_create_pressed():
	disable_buttons(true)
	main_buttons_animation_player.play("out")
	yield(main_buttons_animation_player, "animation_finished")

	var status_code = Server.try_create_server()
	if len(textbox_username.text) < min_name_length:
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
		
	disable_buttons(false)
	main_buttons_animation_player.play("in")




func disable_buttons(will_disable):
	$MainButtonsContainer/JoinContainer/ButtonJoin.disabled = will_disable
	$MainButtonsContainer/ButtonCreate.disabled = will_disable