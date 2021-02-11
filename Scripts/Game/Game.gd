extends Control


#onready var events = $Events
onready var drawing_canvas_node = $DrawingCanvas
onready var players_list_node = $PlayersList
onready var text_round_info_node = $TextRoundInfo
onready var text_prompt_node = $TextPrompt




func _ready():
	Events.connect("new_data", self, "on_new_data")
	$DrawingCanvas/ContainerHostButtons/ButtonNewGame.connect("pressed", self, "on_button_new_game_pressed")
	$ButtonLeave.connect("pressed", self, "on_button_leave_pressed")

	if Server.server == null:
		$DrawingCanvas/ContainerHostButtons.visible = false
	else:
		#OS.alert("If you want someone to be able to join you over a different network, you must port forward your private IP.\nOther people will then be able to use your public IP to join you.", "Server")
		Events.emit_signal("info", "If you want someone to be able to join you over a different network, you must port forward your private IP.\nOther people will then be able to use your public IP to join you.")



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
	
	# if voting time, then add buttons instead
	if Client.round_data.gamestate == 2:
		for player in Client.list_of_players: 
			var vote_button = Button.new()
			vote_button.rect_size = Vector2(80, 50)
			vote_button.text = player.name

			players_list_node.add_child(vote_button)
			vote_button.show()
		return
	
	# Add a new RichTextLabel for each player in list_of_players
	for player in Client.list_of_players:
		var player_to_add = RichTextLabel.new()
		
		player_to_add.fit_content_height = true
		player_to_add.push_color(player.color)
		if player.client_id == Client.this_player.client_id:
			player_to_add.add_text(player.name + " (you)")
		else:
			player_to_add.add_text(player.name)
		
		players_list_node.add_child(player_to_add)
		
		



func update_round_info():
	if len(Client.list_of_players) <= 1:
		return	# why the fuck do i need this, below if statement will through index 1 doesnt exist error if canvas_data is too big. but its fine afterwards, what the fuck

	if Client.list_of_players[Client.round_data.current_player_turn].client_id == Client.this_player.client_id and Client.round_data.gamestate == 1:
		drawing_canvas_node.allowed_to_draw = true
		$DrawingCanvas/ContainerButtons.visible = true
	else:
		drawing_canvas_node.allowed_to_draw = false
		$DrawingCanvas/ContainerButtons.visible = false
	
	if Client.round_data.gamestate == 0:
		text_round_info_node.bbcode_text = "Game over!\nWaiting for the host to start a new game..."
	elif Client.round_data.gamestate == 1:
		text_round_info_node.bbcode_text = "Round %s\n%s's turn" % [Client.round_data.current_round + 1, Client.list_of_players[Client.round_data.current_player_turn].name]
	elif Client.round_data.gamestate == 2:
		text_round_info_node.bbcode_text = "Time to vote!\nClick on someones name to vote them as pretender."




func update_prompt():
	if Client.this_player.is_pretending:
		text_prompt_node.bbcode_text = "Figure out the prompt!"
	else:
		text_prompt_node.bbcode_text = "Draw %s" % Client.prompt



func on_button_new_game_pressed():
	Events.emit_signal("new_game")




func on_button_leave_pressed():
	Server.server = null
	Client.client = null
	Server.list_of_players = []
	Client.list_of_players = []
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
