extends Panel



onready var game_node = get_parent()

var current_mouse_pos
var is_currently_drawing = false
var is_mouse_on_canvas = false
var allowed_to_draw = false



func _ready():
	$ContainerButtons/ButtonClear.connect("pressed", self, "on_button_clear_pressed")
	$ContainerButtons/ButtonSubmit.connect("pressed", self, "on_button_submit_pressed")
	
	
	
func _draw():
	#if len(Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn]) == 0:
	#	return # i honestly dont remember why i had this here
	for game_round in range(len(Client.canvas_data)):
		for game_turn in range(len(Client.canvas_data[game_round])):
			for line in Client.canvas_data[game_round][game_turn]:
				draw_line(line.from_pos, line.to_pos, line.color, line.width, true)
	
	
	
func _process(_delta):
	current_mouse_pos = get_local_mouse_position()

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and check_if_mouse_hover() and allowed_to_draw:
		add_line()
		is_currently_drawing = true
	else:
		is_currently_drawing = false
	
	update()
	


func add_line():
	var turn_canvas_data = Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn]
	var line_to_add
	if is_currently_drawing:
		# Continue the current stroke
		line_to_add = {
			from_pos = turn_canvas_data[len(turn_canvas_data) - 1].to_pos,
			to_pos = current_mouse_pos,
			color = Client.this_player.color,
			width = 5
		}
	else:
		# Start a new stroke, dont draw a line from the last point
		line_to_add = {
			from_pos = current_mouse_pos,
			to_pos = current_mouse_pos,
			color = Client.this_player.color,
			width = 5
		}
	Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn].append(line_to_add)



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



func on_button_clear_pressed():
	Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn].clear()
	update()



func on_button_submit_pressed():
	Events.emit_signal("new_turn")
