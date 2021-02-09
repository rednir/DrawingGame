extends Panel



onready var game_node = get_parent()

var canvas_data = []
var current_mouse_pos
var is_currently_drawing = false
var is_mouse_on_canvas = false



func _ready():
	$ContainerButtons/ButtonClear.connect("pressed", self, "on_button_clear_pressed")
	$ContainerButtons/ButtonSubmit.connect("pressed", self, "on_button_submit_pressed")
	
	
	
func _draw():
	for game_round in canvas_data:
		for line in game_round:
			draw_line(line.from_pos, line.to_pos, line.color, line.width, true)
	
	
	
func _process(_delta):
	current_mouse_pos = get_local_mouse_position()

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and check_if_mouse_hover():
		add_line()
		is_currently_drawing = true
		update()
	else:
		is_currently_drawing = false
	


func add_line():
	var line_to_add
	if is_currently_drawing:
		# Continue the current stroke
		line_to_add = {
			from_pos = canvas_data[game_node.current_round - 1][len(canvas_data[game_node.current_round - 1]) - 1].to_pos,
			to_pos = current_mouse_pos,
			color = Color.red,
			width = 5
		}
	else:
		# Start a new stroke, dont draw a line from the last point
		line_to_add = {
			from_pos = current_mouse_pos,
			to_pos = current_mouse_pos,
			color = Color.red,
			width = 5
		}
	canvas_data[game_node.current_round - 1].append(line_to_add)



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
	canvas_data[game_node.current_round - 1].clear()
	update()



func on_button_submit_pressed():
	Events.emit_signal("new_round")
	Client.client.get_peer(1).put_var("new round happenedddsfsf")
	pass
