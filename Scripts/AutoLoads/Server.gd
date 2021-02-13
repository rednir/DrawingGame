extends Node


const PORT = 9080
const MIN_PLAYERS = 2 # temp
const VOTING_ROUND = 2
const DEFAULT_ROUND_DATA = {
	gamestate = 0,		# 0 is game over, 1 is game running, 2 is voting time
	current_round = 0,
	current_player_turn = 0,
	is_one_line = false,
	pretender = null
}
const DEFAULT_PLAYER = {
	name = "Unspecified",
	color = null,
	client_id = null,
	is_pretending = false,
	amount_of_votes = 0,
	has_voted = false
}


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
	Color.turquoise,
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

var round_data = DEFAULT_ROUND_DATA

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



func on_close_request(id, _code, reason):
	print("[Server] Client %s sent close request with reason: %s" % [id, reason])




func try_create_server():
	server = WebSocketServer.new()
	server.set_buffers(1000000, 1000000, 1000000, 1000000)	# quick fix for issues with canvas_data sending too much data and client closing as a result
	server.encode_buffer_max_size = 1000000					#	
	
	server.connect("client_connected", self, "on_connected")
	server.connect("client_disconnected", self, "on_disconnected")
	server.connect("client_close_request", self, "on_close_request")
	server.connect("data_received", self, "on_data_recieved")
	
	return server.listen(PORT)



func on_data_recieved(id):
	var packet = server.get_peer(id).get_var()
	print("[Server] Data recieved from %d: %s " % [id, packet])

	if packet.name == "this_player":
		# the player has just joined
		# add new player to the server's list of players, then update the client with game data
		add_new_player(packet.data, id)
		send_data_to_clients("list_of_players", list_of_players)	# all clients need to update their list_of_players
		send_data_to_client_by_id("canvas_data", canvas_data, id)
		send_data_to_client_by_id("round_data", round_data, id)
		send_data_to_client_by_id("prompt", prompt, id)

	elif packet.name == "canvas_data":
		canvas_data = packet.data
		#send_data_to_clients("canvas_data", canvas_data) dont think i need this 
	
	elif packet.name == "list_of_players":		# as of writing this, only used when adding votes
		list_of_players = packet.data
		send_data_to_clients("list_of_players", list_of_players)
		if check_if_everyone_has_voted():
			round_data.gamestate = 0
			send_data_to_clients("everyone_has_voted", null)

	elif packet.name == "new_turn":
		if len(canvas_data[len(canvas_data) - 1]) >= len(list_of_players):
			# create new round if amount of turns >= amount of players
			round_data.current_round += 1
			round_data.current_player_turn = 0

			if round_data.current_round == VOTING_ROUND:
				round_data.gamestate = 2
			
			canvas_data.append([])
			canvas_data[len(canvas_data) - 1].append([])
		else:
			round_data.current_player_turn += 1
			canvas_data[len(canvas_data) - 1].append([])
		
		send_data_to_clients("canvas_data", canvas_data)
		send_data_to_clients("round_data", round_data)
	
	



func check_if_everyone_has_voted():
	for player in list_of_players:
		if player.has_voted == false:
			return false
	return true



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
		var unavailable_color = available_colors.find(player.color)
		if unavailable_color != -1:
			available_colors.remove(available_colors.find(player.color))

	if len(available_colors) == 0:
		return Color.whitesmoke
	else:
		return available_colors[0]




func on_new_game():
	if len(list_of_players) < MIN_PLAYERS:
		Events.emit_signal("error", "In order to create a new round, you must have at least %s players connected." % MIN_PLAYERS)
		return

	canvas_data = [[[]]]

	round_data.gamestate = 1
	round_data.current_round = 0
	round_data.current_player_turn = 0

	for player in list_of_players:
		player.is_pretending = false
		player.amount_of_votes = 0
		player.has_voted = false

	randomize()
	var pretender_index = randi() % len(list_of_players)
	round_data.pretender = list_of_players[pretender_index]
	list_of_players[pretender_index].is_pretending = true
	prompt = possible_prompts[randi() % len(possible_prompts) - 1]

	send_data_to_clients("canvas_data", canvas_data)
	send_data_to_clients("round_data", round_data)
	send_data_to_clients("list_of_players", list_of_players)
	send_data_to_clients("prompt", prompt)
	send_data_to_clients("new_game", null)
