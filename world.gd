extends Node

@onready var main_menu = $"CanvasLayer/Main Menu"
const scene = preload("res://environment.tscn")
const Player = preload("res://player.tscn") # preload?

var peer
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 9999
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 10
# creates a new Enet peer which is an object that can either be a client or a server.
# Enet is a networking protocol in Godot that handles UDP-based communications.
 
# global player info with keys being each player's unique id
var player_info = {"name": "Name"} ### selon user input
var players_loaded = 0

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_button_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS) # like a try catch
	if error:
		return error
	## need to compress bandwidth usage?
	# assigns the enet server to multiplayer API, tells godot to use it as multiplayer backend
	multiplayer.multiplayer_peer = peer
	send_player_info($"CanvasLayer/Main Menu/MarginContainer/VBoxContainer/UsernameInput".text, multiplayer.get_unique_id())

func _on_join_button_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

@rpc("any_peer", "call_local")
func start_game():
	var s = scene.instantiate()
	add_child(s)
	main_menu.hide()
	

func _on_start_game_pressed() -> void:
	start_game.rpc()
	

# called from clients and server
func _on_player_connected(id):
	print("Player " + str(id) + " connected")
	_register_player.rpc_id(id, player_info)

# called from clients and server
func _on_player_disconnected(id):
	print("Player " + str(id) + " disconnected")
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	
# called only from clients
func _on_connected_ok():
	print("connected to server")
	send_player_info.rpc_id(1, $"CanvasLayer/Main Menu/MarginContainer/VBoxContainer/UsernameInput".text, multiplayer.get_unique_id())

# called only from clients
func _on_connected_fail():
	print("connection failed")
	multiplayer.multiplayer_peer = null

@rpc("any_peer")
func send_player_info(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for player in GameManager.Players:
			send_player_info.rpc(GameManager.Players[player].name, player)
	
############################################################################
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)
	
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	pass


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	pass

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()
