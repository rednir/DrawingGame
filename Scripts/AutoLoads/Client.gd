extends Node


var client = null

var list_of_players = []
var this_player = Server.DEFAULT_PLAYER

var round_data = Server.DEFAULT_ROUND_DATA
var canvas_data = [[[]]]
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
	client.connect("connection_closed", self, "on_closed")
	client.connect("connection_error", self, "on_closed")
	client.connect("data_received", self, "on_data_recieved")
	
	return client.connect_to_url("ws://%s:%s" % [url, Server.PORT])




func on_connected(_proto = ""):
	print("[Client] Connected")
	client.get_peer(1).put_var({
		name = "this_player",
		data = this_player
	})




func on_closed(was_clean = false):
	print("[Client] Closed, was_clean=" + str(was_clean))




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
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")	# wait until dialog box has been closed
		round_data.gamestate = 0
	elif packet.name == "kick":
		leave_game()
		Events.emit_signal("info", "The server asked you to leave for the following reason:\n%s" % packet.data)

	Events.emit_signal("new_data")



func leave_game():
	Server.server = null
	Server.list_of_players = []
	Server.prompt = "[Game not started]"
	Server.canvas_data = [[[]]]
	Server.round_data = Server.DEFAULT_ROUND_DATA

	Client.client = null
	Client.list_of_players = []
	Client.prompt = "Server hasn't given a prompt"
	Client.canvas_data = [[[]]]
	Client.round_data = Server.DEFAULT_ROUND_DATA
	Client.this_player = Server.DEFAULT_PLAYER
	
	get_tree().change_scene("res://Scenes/MainMenu.tscn")




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
