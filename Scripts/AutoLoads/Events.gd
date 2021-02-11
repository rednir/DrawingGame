extends Node



signal new_turn
signal new_data
signal new_game
signal error(message)
signal info(message)


var dialog
var dialog_bg
var dialog_bg_style = StyleBoxFlat.new()



func _ready():
	connect("error", self, "on_error")
	connect("info", self, "on_info")



func show_dialog(title, message):
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



func on_info(message):
	show_dialog("Info", message)




func on_dialog_close():
	if dialog_bg != null:
		dialog_bg.queue_free()
	if dialog != null:
		dialog.queue_free()
