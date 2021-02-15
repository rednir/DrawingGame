extends Node


var client = null

var list_of_players = []
var this_player = Server.DEFAULT_PLAYER.duplicate(true)

var round_data = Server.DEFAULT_ROUND_DATA.duplicate(true)
var canvas_data = Server.DEFAULT_CANVAS_DATA.duplicate(true)
var prompt = "Server hasn't given a prompt"



func _ready():
	Events.connect("new_turn", self, "on_new_turn")
	



func _process(_delta):
	if client != null:
		client.poll()



func try_join_server(url):
	client = WebSocketClient.new()
	client.set_buffers(1000000, 1000000, 1000000, 1000000)	# quick fix for issues with canvas_data sending too much data and client closing as a result
	client.encode_buffer_max_size = 1000000					#
	
	client.connect("connection_established", self, "on_connected")
	client.connect("connection_closed", self, "on_closed", [], CONNECT_DEFERRED)	# error message tells me i need to use this flag when setting client to null
	client.connect("connection_error", self, "on_closed")
	client.connect("data_received", self, "on_data_recieved")
	
	return client.connect_to_url("ws://%s:%s" % [url, Server.PORT])




func on_connected(_proto = ""):
	print("[Client] Connected")
	VisualServer.set_default_clear_color(Color("2c2c54"))
	for _i in range (1):		# for easy debugging
		client.get_peer(1).put_var({
			name = "this_player",
			data = this_player
		})




func on_closed(was_clean = false):
	if this_player == Server.DEFAULT_PLAYER:
		was_clean = true		# if never connected, i want to activate the unexpected disconnection message

	print("[Client] Closed, was_clean=" + str(was_clean))
	
	Server.list_of_players = []
	Server.prompt = "[SERVER INITAL PROMPT]"
	Server.canvas_data = Server.DEFAULT_CANVAS_DATA.duplicate(true)
	Server.round_data = Server.DEFAULT_ROUND_DATA.duplicate(true)
	Server.server = null

	if was_clean and Engine.get_main_loop().current_scene.get_name() != "MainMenuControl":		# i dont understand why, but when i close cleanly, was_clean is false. how does that make any sense. but this works for now. maybe docs are wrong?
		Events.emit_signal("error", "The connection to the server was lost unexpectedly.")
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")

	Client.list_of_players = []
	Client.prompt = "Server hasn't given a prompt"
	Client.canvas_data = Server.DEFAULT_CANVAS_DATA.duplicate(true)
	Client.round_data = Server.DEFAULT_ROUND_DATA.duplicate(true)
	Client.this_player = Server.DEFAULT_PLAYER.duplicate(true)
	Client.client = null

	if Engine.get_main_loop().current_scene.get_name() == "MainMenuControl":
		return

	get_tree().change_scene("res://Scenes/MainMenu.tscn")




func on_data_recieved():
	var packet = client.get_peer(1).get_var()
	print("[Client] Data recieved:" + str(packet))

	if packet.name == "list_of_players":
		list_of_players = packet.data
		if this_player.client_id == null:
			# when player first connects, its easy to find the updated this_player
			this_player = list_of_players[len(list_of_players) - 1]
		else:
			# otherwise we still need to find the updated version of this_player
			for player in list_of_players:
				if player.client_id == this_player.client_id:
					print("assigning new this_player")
					print(this_player)
					this_player = player
					break

	elif packet.name == "canvas_data":
		canvas_data = packet.data

	elif packet.name == "round_data":
		round_data = packet.data

	elif packet.name == "prompt":
		prompt = packet.data

	elif packet.name == "new_game":
		Events.emit_signal("info", "It's a new game!\nYou are %s." % ("pretending, and must blend in" if this_player.is_pretending else "drawing, and must find the pretender"))
	
	elif packet.name == "everyone_has_voted":
		Events.emit_signal("info", "Game over!\nThe pretender was %s!" % round_data.pretender.name)
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")
		round_data.gamestate = 0

	elif packet.name == "kick":
		Events.emit_signal("info", "The server asked you to leave for the following reason:\n%s" % packet.data)
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")
		client.disconnect_from_host()

		
	Events.emit_signal("new_data", packet.name)





func on_new_turn():
	client.get_peer(1).put_var({
		name = "canvas_data",
		data = canvas_data
	})
	client.get_peer(1).put_var({
		name = "new_turn",
		data = round_data
	})




func check_if_this_player_turn():
	if len(list_of_players) > 0 and round_data.current_player_turn < len(list_of_players):
		return list_of_players[round_data.current_player_turn].client_id == this_player.client_id and round_data.gamestate == 1
	else:
		return false
