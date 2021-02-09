extends Node


const PORT = 9080
var server = null

var list_of_players = [
	{
		client_id = -1,
		name = "other",
		color = Color.blue
	},
	{
		client_id = -1,
		name = "yeah",
		color = Color.violet
	},
]


func _ready():
	pass



func _process(_delta):
	if server != null:
		server.poll()



func on_connected(id, protocol):
	print("[Server] Client %d connected" % id)



func on_diconnected(id, was_clean = false):
	print("[Server] Client %d disconnected, clean: %s" % [id, str(was_clean)])



func try_create_server():
	server = WebSocketServer.new()
	
	server.connect("client_connected", self, "on_connected")
	server.connect("client_disconnected", self, "on_disconnected")
	server.connect("client_close_request", self, "on_close_request")
	server.connect("data_received", self, "on_data_recieved")
	
	return server.listen(PORT)



func on_data_recieved(id):
	var packet = server.get_peer(id).get_var()
	print("[Server] From %d: %s " % [id, packet])
	if packet is Dictionary:
		add_new_player(packet, id)
		server.get_peer(id).put_var(list_of_players)
	else:
		server.get_peer(id).put_var(list_of_players)



func add_new_player(player, id):
	player.client_id = id
	list_of_players.append(player)
	print(list_of_players)
