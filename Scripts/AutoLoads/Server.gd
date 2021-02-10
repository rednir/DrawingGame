extends Node


const PORT = 9080
var server = null

var player_colors = [
	Color.green,
	Color.blue,
	Color.red,
	Color.yellow,
	Color.pink
]

var list_of_players = [
	{
		client_id = null,
		name = "other",
		color = Color.green
	},
	{
		client_id = null,
		name = "yeah",
		color = Color.blue
	},
]


func _ready():
	pass



func _process(_delta):
	if server != null:
		server.poll()



func on_connected(id, _protocol):
	print("[Server] Client %d connected" % id)



func on_disconnected(id, was_clean = false):
	print("[Server] Client %d disconnected, clean: %s" % [id, str(was_clean)])

	# Find the player that disconnected in list_of_players and remove it
	for i in range(len(list_of_players)):
		if list_of_players[i].client_id == id:
			list_of_players.remove(i)
			send_players_list_to_clients()
			return



func on_close_request():
	print("[Server] Close request")



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
		# client has sent its player info, i want to add this to the server's list of players
		add_new_player(packet, id)
	
	# update clients with new list_of_players
	send_players_list_to_clients()



func send_players_list_to_clients():
	for player in list_of_players:
		if player.client_id == null:
			continue
		print("Sending players list to %s" % player.client_id)
		server.get_peer(player.client_id).put_var(list_of_players)



func add_new_player(player, id):
	player.client_id = id
	player.color = get_next_available_color()
	list_of_players.append(player)
	print(list_of_players)



func get_next_available_color():
	var available_colors = player_colors
	for player in list_of_players:
		available_colors.remove(available_colors.find(player.color))

	if len(available_colors) == 0:
		return null
	else:
		return available_colors[0]
