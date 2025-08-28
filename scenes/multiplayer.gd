extends Node2D

var peer = ENetMultiplayerPeer.new()

signal connected
signal server_started

func host_game(port: int = 135):
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	emit_signal("server_started")
	print("Servidor creado en puerto ", port)
	rpc("rpc_start_game", randi())

func join_game(ip: String = "127.0.0.1", port: int = 135):
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)

func _on_connected():
	emit_signal("connected")
	print("Cliente conectado al servidor")


func _on_button_pressed() -> void:
	host_game()


func _on_button_2_pressed() -> void:
	join_game()


func _on_join_pressed() -> void:
	pass # Replace with function body.
