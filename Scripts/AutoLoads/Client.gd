extends Node


var client = null

var list_of_players = []
var this_player = {
	name = "Unspecified",
	color = null,
	client_id = null,
	is_pretending = false,
	amount_of_votes = 0,
	has_voted = false
}

var round_data = {
	gamestate = 0,
	current_round = 0,
	current_player_turn = 0,
	pretender = null
}

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
		Events.emit_signal("info", "It's a new game!\nYou are %s." % ("pretending, and must blend in." if this_player.is_pretending else "drawing, and must find the pretender"))
	elif packet.name == "everyone_has_voted":
		Events.emit_signal("info", "Game over!\nThe pretender was %s!" % round_data.pretender.name)
		yield(Engine.get_main_loop().current_scene.get_node("AcceptDialog"), "hide")	# wait until dialog box has been closed
		round_data.gamestate = 0

	Events.emit_signal("new_data")




func on_new_turn():
	client.get_peer(1).put_var({
		name = "canvas_data",
		data = canvas_data
	})
	client.get_peer(1).put_var({
		name = "new_turn",
		data = round_data
	})
