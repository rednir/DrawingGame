extends Node



signal new_turn
signal new_data(updated_data)
signal new_game
signal error(message)
signal info(message)


var dialog
var dialog_bg
var dialog_bg_style = StyleBoxFlat.new()

var sound_player
var sound = { 
	notify_high = preload("res://Resources/notify_high.wav"),
	notify_low = preload("res://Resources/notify_low.wav"),
	clear = preload("res://Resources/clear.wav")
}



func _ready():
	connect("error", self, "on_error")
	connect("info", self, "on_info")
	


func play_sound(sound_name):
	#if Engine.get_main_loop().current_scene.get_node_or_null("SoundPlayer") != null:
	#	sound_player.queue_free()
		
	sound_player = AudioStreamPlayer.new()
	sound_player.name = "SoundPlayer"
	Engine.get_main_loop().current_scene.add_child(sound_player)
	sound_player.stream = sound.get(sound_name)
	sound_player.play()
	yield(sound_player, "finished")
	
	if sound_player != null:
		sound_player.queue_free()




func show_dialog(title, message):
	#OS.alert(message, title)
	if dialog != null:
		dialog.queue_free()

	dialog = AcceptDialog.new()
	dialog.name = "AcceptDialog"

	dialog.window_title = title
	dialog.dialog_text = message
	dialog.connect("hide", self, "on_dialog_close")
	dialog.popup_exclusive = true

	Engine.get_main_loop().current_scene.add_child(dialog)
	dialog.popup_centered()

	return # i need to fix the below crashing on exported version, something to do with the bg i think


	on_dialog_close()

	dialog = AcceptDialog.new()
	dialog_bg = Panel.new()
	
	dialog_bg_style.bg_color = Color(0, 0, 0, 0.5)
	
	dialog.window_title = title
	dialog.dialog_text = message
	dialog.connect("hide", self, "on_dialog_close")
	dialog.popup_exclusive = true
	
	dialog_bg.add_child(dialog)
	dialog_bg.rect_position = Vector2(0, 0)
	dialog_bg.rect_size = Vector2(1024, 600)
	dialog_bg.set("custom_styles/panel", dialog_bg_style)

	Engine.get_main_loop().current_scene.add_child(dialog_bg)
	dialog.popup_centered()
	dialog_bg.show()




func on_error(message):
	show_dialog("Error", message)
	play_sound("notify_high")



func on_info(message):
	show_dialog("Info", message)
	play_sound("notify_high")




func on_dialog_close():
	if dialog_bg != null:
		dialog_bg.queue_free()
	if dialog != null:
		dialog.queue_free()
