extends Control


onready var textbox_join = $MainButtonsContainer/JoinContainer/TextboxJoin


func _ready():
	$MainButtonsContainer/JoinContainer/ButtonJoin.connect("pressed", self, "on_button_join_pressed")
	$MainButtonsContainer/ButtonCreate.connect("pressed", self, "on_button_create_pressed")
	pass



func on_button_join_pressed():
	var status_code = Client.try_join_server(textbox_join.text)
	if status_code != OK:
		Events.emit_signal("error", "Could not join the server (Code: %s)\nMake sure the IP address exists." % status_code)
	else:
		get_tree().change_scene("res://Scenes/Game.tscn")



func on_button_create_pressed():
	var status_code = Server.try_create_server()
	if status_code != OK:
		Events.emit_signal("error", "Could not create a server (Code: %s)" % status_code)
	else:
		Client.try_join_server("localhost")
		get_tree().change_scene("res://Scenes/Game.tscn")
