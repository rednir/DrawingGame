extends Control


const LoadingIconScene = preload("res://Scenes/LoadingIcon.tscn")
const SettingsScene = preload("res://Scenes/SettingsMenu.tscn")


onready var drawing_canvas_node = $DrawingCanvas
onready var players_list_node = $PlayersListScrollContainer/PanelContainer/PlayersList
onready var text_round_info_node = $TextRoundInfo
onready var text_prompt_node = $TextPrompt
onready var loading_icon_instance = LoadingIconScene.instance()


var settings_instance



func _ready():
	Events.connect("new_data", self, "on_new_data")
	Client.client.connect("connection_established", self, "on_connected")
	$ButtonLeave.connect("pressed", self, "on_button_leave_pressed")

	$DrawingCanvas/ContainerButtons.visible = false

	if Server.server == null:
		$HostTools.visible = false
	else:
		$HostTools/GameControlContainer/ButtonNewGame.connect("pressed", self, "on_button_new_game_pressed")
		$HostTools/GameControlContainer/CheckboxOneLine.connect("toggled", self, "on_host_setting_toggled", ["is_one_line"])
		$HostTools/GameControlContainer/CheckboxNoClear.connect("toggled", self, "on_host_setting_toggled", ["is_no_clear"])
		$HostTools/ButtonHelpJoin.connect("pressed", self, "on_button_help_join_pressed")

	self.add_child(loading_icon_instance)




func _process(delta):
	if Input.get_action_strength("open_settings") == 1 and settings_instance == null:
		on_button_settings_pressed()




func on_connected(_proto = ""):
	loading_icon_instance.get_node("AnimationPlayer").play("out")
		



func on_new_data(updated_data):
	match updated_data:

		"list_of_players":
			update_players_list()

		"prompt":
			update_prompt()
		
		"round_data":
			update_round_info()
			update_players_list()	# cheap way of doing this, but if its voting round i also need players list to update to create buttons
		
		"canvas_data":
			if Client.round_data.gamestate != 0:
				# Only do this if player hasnt just joined
				$DrawingCanvas.canvas_animation_player.play("pulse_green")
				Events.play_sound("notify_low")
			drawing_canvas_node.update()

		_:
			update_players_list()
			update_prompt()
			update_round_info()
			drawing_canvas_node.update()




func update_players_list():
	if Server.server != null:
			$HostTools/ButtonHelpJoin.visible = len(Client.list_of_players) <= 1

	# First remove all players in the list
	for child in players_list_node.get_children():
		players_list_node.remove_child(child)
		child.queue_free()
	
	# if voting time, then add buttons instead
	if Client.round_data.gamestate == 2:
		var i = 0
		for player in Client.list_of_players: 
			var vote_button = Button.new()
			vote_button.rect_size = Vector2(80, 50)
			vote_button.add_color_override("font_color", player.color)
			vote_button.margin_left = 10.0
			vote_button.text = player.name + " (%s votes)" % player.amount_of_votes
			if Client.this_player.has_voted:
				vote_button.disabled = true

			players_list_node.add_child(vote_button)
			vote_button.connect("pressed", self, "on_button_vote_pressed", [i])
			vote_button.show()
			
			i += 1
		return
	
	# Add a new RichTextLabel for each player in list_of_players
	for player in Client.list_of_players:
		var player_to_add = RichTextLabel.new()
		
		player_to_add.fit_content_height = true
		player_to_add.push_color(player.color)
		if player.client_id == Client.this_player.client_id:
			player_to_add.add_text("  " + player.name + " (you)")
		else:
			player_to_add.add_text("  " + player.name)
		
		players_list_node.add_child(player_to_add)
		
		



func update_round_info():
	if len(Client.list_of_players) <= 1:
		return	# why the fuck do i need this, below if statement will through index 1 doesnt exist error if canvas_data is too big. but its fine afterwards, what the fuck
	
	if Client.round_data.gamestate == 0:
		text_round_info_node.bbcode_text = "Game over!\nWaiting for the host to start a new game..."
	elif Client.round_data.gamestate == 1:
		text_round_info_node.bbcode_text = "Round %s\n%s's turn" % [Client.round_data.current_round + 1, Client.list_of_players[Client.round_data.current_player_turn].name]
	elif Client.round_data.gamestate == 2:
		text_round_info_node.bbcode_text = "Time to vote!\nClick on someones name to vote them as pretender."
	
	if Client.check_if_this_player_turn():
		drawing_canvas_node.allowed_to_draw = true
		$DrawingCanvas/ContainerButtons.visible = true
		text_round_info_node.bbcode_text = "Round %s\n%s's turn (%s/%s)" % [Client.round_data.current_round + 1, Client.list_of_players[Client.round_data.current_player_turn].name, len(Client.canvas_data[Client.round_data.current_round][Client.round_data.current_player_turn]), drawing_canvas_node.MAX_PER_TURN]
	else:
		drawing_canvas_node.allowed_to_draw = false
		$DrawingCanvas/ContainerButtons.visible = false

	if Client.round_data.is_one_line and Client.round_data.gamestate == 1:
		text_round_info_node.append_bbcode("\nOne line mode is on!")
		




func update_prompt():
	if Client.round_data.gamestate == 0:
		text_prompt_node.bbcode_text = "Waiting for host to start..."
	else:
		if Client.this_player.is_pretending:
			text_prompt_node.bbcode_text = "Figure out the prompt!"
		else:
			text_prompt_node.bbcode_text = "Draw %s" % Client.prompt




func on_button_settings_pressed():
	settings_instance = SettingsScene.instance()
	self.add_child(settings_instance)




func on_button_new_game_pressed():
	Events.emit_signal("new_game")




func on_button_leave_pressed():
	if Client.round_data.gamestate == 0:
		# if the game is over, no need to ask confirmation
		on_leave_game_confirmed()
	else:
		Events.emit_signal("question", "The game is in progress.\nReally leave?")
		Engine.get_main_loop().current_scene.get_node("ConfirmationDialog").get_ok().connect("pressed", self, "on_leave_game_confirmed")



func on_leave_game_confirmed():
	$ButtonLeave.disabled = true
	$ButtonLeave.text = "Leaving..."
	drawing_canvas_node.canvas_animation_player.play_backwards("in")
	yield(drawing_canvas_node.canvas_animation_player, "animation_finished")
	#Client.client.disconnect_from_host(1000, "Client requested to leave game")
	Client.on_closed()




func on_button_vote_pressed(player_index):
	#for child in players_list_node.get_children():
		#child.disabled = true
	Client.this_player.has_voted = true
	
	Client.list_of_players[player_index].amount_of_votes += 1
	Client.client.get_peer(1).put_var({
		name = "list_of_players",
		data = Client.list_of_players
	})




func on_host_setting_toggled(is_on, key):
	Client.round_data[key] = is_on
	Client.client.get_peer(1).put_var({
		name = "round_data",
		data = Client.round_data
	})



func on_button_help_join_pressed():
	Events.emit_signal("info", "If you want someone to be able to join you over a different network, you must port forward your private IP with port %s.\nOther people will then be able to use your public IP (%s) to join you." % [Server.PORT, Server.public_ip])
