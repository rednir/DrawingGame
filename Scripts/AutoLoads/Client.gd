extends Node


var client = null

var list_of_players = []
var this_player = {
	name = "rednir",
	color = null,
	client_id = null
}

var round_data = {
	current_round = 0,
	current_player_turn = 0
}

var canvas_data = [[[]]]
var prompt = "CHAIR"



func _ready():
	Events.connect("new_turn", self, "on_new_turn")
	



func _process(_delta):
	if client != null:
		client.poll()



func try_join_server(url):
	client = WebSocketClient.new()
	
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



func on_data_recieved():
	var packet = client.get_peer(1).get_var()
	print("[Client] Data recieved:" + str(packet))

	if packet.name == "list_of_players":
		list_of_players = packet.data
		if this_player.client_id == null:
			# this happens when client first connects
			this_player = list_of_players[len(list_of_players) - 1]
	elif packet.name == "canvas_data":
		canvas_data = packet.data
	elif packet.name == "round_data":
		round_data = packet.data

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