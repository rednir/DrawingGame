extends Control


#onready var events = $Events
onready var drawing_canvas_node = $DrawingCanvas
onready var players_list_node = $PlayersList
onready var text_round_info_node = $TextRoundInfo
onready var text_prompt_node = $TextPrompt



func _ready():
	#Events.connect("new_round", self, "on_new_round")
	Events.connect("new_data", self, "on_new_data")
	#Events.emit_signal("new_round")



func _process(_delta):
	pass



func on_new_data():
	update_players_list()
	update_prompt()
	update_round_info()
	drawing_canvas_node.update()



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



func update_round_info():
	text_round_info_node.bbcode_text = "Round %s\n%s's turn" % [Client.round_data.current_round + 1, Client.list_of_players[Client.round_data.current_player_turn].name]
	print(Client.list_of_players[Client.round_data.current_player_turn])
	print(Client.this_player)
	if Client.list_of_players[Client.round_data.current_player_turn].client_id == Client.this_player.client_id:
		drawing_canvas_node.allowed_to_draw = true
	else:
		drawing_canvas_node.allowed_to_draw = false



func update_prompt():
	text_prompt_node.bbcode_text = "Draw a %s" % Client.prompt
	print(Server.server)
	if Server.server != null:
		text_prompt_node.bbcode_text = "You are the server"
