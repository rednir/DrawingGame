extends Node



var client = null

var this_player = {
	name = "rednir",
	color = Color.red,
	client_id = -1
}
var list_of_players = []


func _ready():
	pass



func _process(delta):
	if client != null:
		client.poll()



func try_join_server(url):
	client = WebSocketClient.new()
	
	client.connect("connection_established", self, "on_connected")
	client.connect("connection_closed", self, "on_closed")
	client.connect("connection_error", self, "on_closed")
	client.connect("data_received", self, "on_data_recieved")
	
	return client.connect_to_url("ws://%s:%s" % [url, Server.PORT])



func on_connected(proto = ""):
	print("[Client] Connected")
	client.get_peer(1).put_var(this_player)



func on_data_recieved():
	var packet = client.get_peer(1).get_var()
	print("[Client] Data recieved:" + str(packet))
	if packet is Array:
		list_of_players = packet
	Events.emit_signal("new_data")
