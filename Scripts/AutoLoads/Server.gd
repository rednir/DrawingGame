extends Node


const PORT = 9080
const MIN_PLAYERS = 3
var server = null

var possible_prompts = [
	"diary", "bottle", "water", "packet", "chewing gum", "tissue", "glasses", "watch", "sweet", "photo", "camera", "stamp", "postcard", "dictionary", "coin", "brush", "credit card", "identity", "card", "key", "mobile", "phone", "wallet", "button", "umbrella", "pen", "pencil", "lighter", "cigarette", "match", "lipstick", "purse", "case", "clip", "scissors", "rubber", "file", "banknote", "passport", "driving, licence", "comb", "notebook", "laptop", "rubbish", "mirror", "painkiller", "sunscreen", "toothbrush", "headphone", "player", "battery", "light bulb", "bin", "newspaper", "magazine", "alarm clock"
]
var prompt = "[Game not started]"

var player_colors = [
	Color.green,
	Color.red,
	Color.yellow,
	Color.pink,
	Color.indigo,
	Color.violet,
	Color.yellowgreen,
	Color.salmon,
	Color.purple,
	Color.cyan
]

var list_of_players = [
	#{
	#	client_id = null,
	#	name = "other",
	#	color = Color.green
	#},
]

var round_data = {
	game_over = true,
	current_round = 0,
	current_player_turn = 0
}

var canvas_data = [[[]]]



func _ready():
	Events.connect("new_game", self, "on_new_game")
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
			send_data_to_clients("list_of_players", list_of_players)
			return



func on_close_request():
	print("[Server] Close request")




func try_create_server():
	server = WebSocketServer.new()
	
	server.connect("client_connected", self, "on_connected")
	server.connect("client_disconnected", self, "on_disconnected")
	server.connect("client_close_request", self, "on_close_request")
	server.connect("data_received", self, "on_data_recieved")

	#Events.emit_signal("new_game")
	
	return server.listen(PORT)



func on_data_recieved(id):
	var packet = server.get_peer(id).get_var()
	print("[Server] From %d: %s " % [id, packet])

	if packet.name == "this_player":
		# add new player to the server's list of players, then update the client with game data
		add_new_player(packet.data, id)
		send_data_to_clients("list_of_players", list_of_players)	# all clients need to update their list_of_players
		send_data_to_client_by_id("canvas_data", canvas_data, id)
		send_data_to_client_by_id("round_data", round_data, id)
		send_data_to_client_by_id("prompt", prompt, id)

	elif packet.name == "canvas_data":
		canvas_data = packet.data
		#send_data_to_clients("canvas_data", canvas_data) dont think i need this 

	elif packet.name == "new_turn":
		if len(canvas_data[len(canvas_data) - 1]) >= len(list_of_players):
			# create new round if amount of turns >= amount of players
			round_data.current_round += 1
			round_data.current_player_turn = 0
			
			canvas_data.append([])
			canvas_data[len(canvas_data) - 1].append([])
		else:
			round_data.current_player_turn += 1
			canvas_data[len(canvas_data) - 1].append([])
		
		#print(canvas_data)
		send_data_to_clients("round_data", round_data)
		send_data_to_clients("canvas_data", canvas_data)
	
	# # update clients with new list_of_players
	



func send_data_to_clients(to_send_name, to_send_data):
	for player in list_of_players:
		if player.client_id == null:
			continue
		print("Sending data to %s" % player.client_id)
		server.get_peer(player.client_id).put_var({
			name = to_send_name,
			data = to_send_data
		})



func send_data_to_client_by_id(to_send_name, to_send_data, id):
	print("Sending data to %s" % id)
	server.get_peer(id).put_var({
		name = to_send_name,
		data = to_send_data
	})




func add_new_player(player, id):
	player.client_id = id
	player.color = get_next_available_color()
	list_of_players.append(player)




func get_next_available_color():
	var available_colors = player_colors
	for player in list_of_players:
		available_colors.remove(available_colors.find(player.color))

	if len(available_colors) == 0:
		return null
	else:
		return available_colors[0]




func on_new_game():
	if len(list_of_players) < MIN_PLAYERS:
		Events.emit_signal("error", "In order to create a new round, you must have at least %s players connected." % MIN_PLAYERS)
		return

	canvas_data = [[[]]]
	round_data = {
		current_round = 0,
		current_player_turn = 0
	}

	for player in list_of_players:
		player.is_pretending = false
	randomize()
	list_of_players[randi() % len(list_of_players) - 1].is_pretending = true
	prompt = possible_prompts[randi() % len(possible_prompts) - 1]

	send_data_to_clients("canvas_data", canvas_data)
	send_data_to_clients("round_data", round_data)
	send_data_to_clients("list_of_players", list_of_players)
	send_data_to_clients("prompt", prompt)
	send_data_to_clients("new_game", null)
