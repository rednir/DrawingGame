extends Node



signal new_turn
signal new_data(updated_data)
signal new_game
signal error(message)
signal info(message)
signal question(message)


var accept_dialog
var confirmation_dialog


var sound_player
var sound = { 
	notify_high = preload("res://Resources/Sounds/notify_high.wav"),
	notify_low = preload("res://Resources/Sounds/notify_low.wav"),
	clear = preload("res://Resources/Sounds/clear.wav"),
	volumebar = preload("res://Resources/Sounds/volumebar.wav")
}



func _ready():
	connect("error", self, "on_error")
	connect("info", self, "on_info")
	connect("question", self, "on_question")
	


func play_sound(sound_name):
	#if Engine.get_main_loop().current_scene.get_node_or_null("SoundPlayer") != null:
	#	sound_player.queue_free()
		
	sound_player = AudioStreamPlayer.new()
	Engine.get_main_loop().current_scene.add_child(sound_player)
	sound_player.name = "SoundPlayer"
	sound_player.volume_db = Settings.config.audio.master_volume.value
	sound_player.stream = sound.get(sound_name)
	sound_player.play()
	yield(sound_player, "finished")
	
	#if sound_player != null:
	#	sound_player.queue_free()




func show_accept_dialog(title, message):
	#OS.alert(message, title)
	#if accept_dialog != null:
	#	accept_dialog.hide()

	accept_dialog = AcceptDialog.new()
	accept_dialog.name = "AcceptDialog"

	accept_dialog.window_title = title
	accept_dialog.dialog_text = message
	accept_dialog.connect("hide", self, "on_dialog_close", [accept_dialog])
	accept_dialog.popup_exclusive = true

	Engine.get_main_loop().current_scene.add_child(accept_dialog)
	accept_dialog.popup_centered()

	


func show_confirmation_dialog(title, message):
	#if confirmation_dialog != null:
	#	confirmation_dialog.hide()

	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.name = "ConfirmationDialog"

	confirmation_dialog.window_title = title
	confirmation_dialog.dialog_text = message
	confirmation_dialog.connect("hide", self, "on_dialog_close", [confirmation_dialog])
	confirmation_dialog.popup_exclusive = true

	Engine.get_main_loop().current_scene.add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()




func on_error(message):
	show_accept_dialog("Error", message)
	play_sound("notify_high")



func on_info(message):
	show_accept_dialog("Info", message)
	play_sound("notify_high")



func on_question(message):
	show_confirmation_dialog("Question", message)
	play_sound("notify_high")



func on_dialog_close(dialog):
	if dialog != null:
		dialog.queue_free()
