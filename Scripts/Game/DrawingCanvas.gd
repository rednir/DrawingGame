extends Panel



const MAX_PER_TURN = 300


onready var game_node = get_parent()
onready var button_clear_node = $ContainerButtons/ButtonClear
onready var button_submit_node = $ContainerButtons/ButtonSubmit
onready var canvas_animation_player = $DrawingCanvasAnimation


var current_mouse_pos
var is_currently_drawing = false
var is_mouse_on_canvas = false
var allowed_to_draw = false




func _ready():
	button_clear_node.connect("pressed", self, "on_button_clear_pressed")
	button_submit_node.connect("pressed", self, "on_button_submit_pressed")
	Client.client.connect("connection_established", self, "on_connected")
	
	
	
	
func _draw():
	for game_round in range(len(Client.canvas_data)):
		for game_turn in range(len(Client.canvas_data[game_round])):
			for line in Client.canvas_data[game_round][game_turn]:
				draw_line(line.from_pos, line.to_pos, line.color, line.width)
	
	
	
func _physics_process(_delta):
	if current_mouse_pos == get_local_mouse_position():
		# no point of drawing anything if the mouse position hasn't changed
		return
	
	current_mouse_pos = get_local_mouse_position()
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and check_if_mouse_hover() and allowed_to_draw and Client.round_data.gamestate == 1:
		is_currently_drawing = add_line()
	else:
		is_currently_drawing = false
	
	update()
	
	
	


func add_line():
	var turn_canvas_data = Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn]

	if len(turn_canvas_data) >= MAX_PER_TURN:
		canvas_animation_player.play("pulse_red")
		allowed_to_draw = false
		Events.emit_signal("info", "I think you've drawn a little too much...\nPress clear to restart your drawing.")
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")	# wait for dialog close
		allowed_to_draw = true
		return false
	if Client.round_data.is_one_line and len(turn_canvas_data) > 0 and !is_currently_drawing:
		canvas_animation_player.play("pulse_red")
		allowed_to_draw = false
		Events.emit_signal("info", "One line mode is enabled, and you just used your one line.\nPress the clear button if you think you messed up your drawing.")
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")	# wait for dialog close
		allowed_to_draw = true
		return false


	var line_to_add
	if is_currently_drawing:
		# Continue the current line
		line_to_add = {
			from_pos = turn_canvas_data[len(turn_canvas_data) - 1].to_pos,
			to_pos = current_mouse_pos,
			color = Client.this_player.color,
			width = 3
		}
	else:
		# Start a new line, dont draw a straight line from the last point
		line_to_add = {
			from_pos = current_mouse_pos,
			to_pos = current_mouse_pos,
			color = Client.this_player.color,
			width = 3
		}
	Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn].append(line_to_add)

	if Client.check_if_this_player_turn():
		# When its your turn, round info also shows how much left you can draw, so this should be updated constantly
		game_node.update_round_info()

	return true



func check_if_mouse_hover():
	var relative_mouse_pos = get_viewport().get_mouse_position()
	
	var left = rect_position.x
	var right = rect_position.x + rect_size.x
	var top = rect_position.y
	var bottom = rect_position.y + rect_size.y
	
	if (relative_mouse_pos.x > left and relative_mouse_pos.x < right
		and relative_mouse_pos.y < bottom and relative_mouse_pos.y > top):
			return true
	else:
		return false



func on_connected(_proto = ""):
	#yield(Client.client, "data_received")
	canvas_animation_player.play("in")



func on_button_clear_pressed():
	if Client.round_data.is_no_clear:
		Events.emit_signal("info", "The host has turned clearing off.\nYou'll have to deal with the mistake.")
		return

	Events.play_sound("clear")
	Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn].clear()
	update()



func on_button_submit_pressed():
	Events.emit_signal("new_turn")
