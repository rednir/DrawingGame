extends Control


#onready var events = $Events
onready var drawing_canvas_node = $DrawingCanvas
onready var players_list_node = $PlayersList


var current_round = 0


func _ready():
	Events.connect("new_round", self, "on_new_round")
	Events.connect("new_data", self, "on_new_data")
	Events.emit_signal("new_round")
	pass



func _process(delta):
	pass



func on_new_round():
	print("new round")
	drawing_canvas_node.canvas_data.append([])
	current_round += 1



func on_new_data():
	update_players_list()



func update_players_list():
	# First remove all players in the list
	for child in players_list_node.get_children():
		players_list_node.remove_child(child)
		child.queue_free()
	
	# Then add a new RichTextLabel for each player in list_of_players
	for player in Client.list_of_players:
		var player_to_add = RichTextLabel.new()
		
		player_to_add.fit_content_height = true
		player_to_add.push_color(player.color)
		player_to_add.add_text(player.name)
		
		players_list_node.add_child(player_to_add)
