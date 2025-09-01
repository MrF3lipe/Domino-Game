extends Control

var REQUIRED_PLAYERS := 4
var connected_players := []
var lobby_window: Window
var main_window: Window
@onready var game_scene = preload("res://scenes/Game.tscn")

# Multiplayer peer
var peer: ENetMultiplayerPeer

func _ready():
	randomize()
	await get_tree().process_frame
	main_window = $MainWindow
	main_window.visible = true
	lobby_window = $LobbyWindow
	lobby_window.visible = false
	
	# Conectar botones del MainWindow
	main_window.get_node("Host").pressed.connect(_on_host_pressed)
	main_window.get_node("Join").pressed.connect(_on_join_pressed)

func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	main_window.visible = false
	# El host se cuenta a sí mismo
	_on_player_connected(multiplayer.get_unique_id())
	_show_lobby()

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 135)
	multiplayer.multiplayer_peer = peer
	main_window.visible = false
	_show_lobby()

func _show_lobby():
	lobby_window.visible = true
	update_lobby_info()
	
	var start_button = lobby_window.get_node("StartButton")
	if multiplayer.is_server():
		start_button.visible = true
		start_button.disabled = true
		start_button.pressed.connect(_on_start_pressed)
	else:
		start_button.visible = false
		start_button.disabled = true
	
	# Conectar señales de multiplayer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	# Inicializar jugadores ya conectados
	for id in multiplayer.get_peers():
		_on_player_connected(id)

func update_lobby_info():
	var label = lobby_window.get_node("PlayersLabel")
	label.text = "Jugadores conectados: %d / %d" % [connected_players.size(), REQUIRED_PLAYERS]
	
	var config_label = lobby_window.get_node("ConfigLabel")
	config_label.text = "Jugadores: %d\nFichas por jugador: %d" % [REQUIRED_PLAYERS, 7]

	if multiplayer.is_server():
		var start_button = lobby_window.get_node("StartButton")
		start_button.disabled = connected_players.size() < REQUIRED_PLAYERS

func _on_player_connected(id):
	if multiplayer.is_server():
		if id not in connected_players:
			connected_players.append(id)
		_update_clients_connected_players()
	update_lobby_info()

func _on_player_disconnected(id):
	if multiplayer.is_server():
		if id in connected_players:
			connected_players.erase(id)
		_update_clients_connected_players()
	update_lobby_info()

func _on_start_pressed():
	if connected_players.size() >= REQUIRED_PLAYERS:
		var min_seed = 10000
		var max_seed = 999999
		var seed = randi() % (max_seed - min_seed + 1) + min_seed
		if multiplayer.is_server():
			_start_game(seed)
			rpc("rpc_start_game", seed)

@rpc("any_peer", "reliable")
func rpc_start_game(seed: int):
	_start_game(seed)

@rpc("any_peer", "reliable")
func _update_clients_connected_players():
	rpc("_sync_connected_players", connected_players)

@rpc("any_peer", "reliable")
func _sync_connected_players(list_of_ids):
	connected_players = list_of_ids
	update_lobby_info()

func _start_game(seed: int):
	lobby_window.visible = false
	main_window.visible = false
	var game = game_scene.instantiate()
	game.set_connected_players(connected_players)
	add_child(game)
	game.set_multiplayer_info(multiplayer.multiplayer_peer, multiplayer.is_server())
	game.on_play_pressed()
	game.seed_random_number_generator(seed)
