class_name Game
extends Control

@export var total_players := 4
@export var pieces_per_player := 7
@export var margin := 0.1
@export var piece_spacing := 40
@export var length = 300
@export var width = 100
@export var piece_scale = 0.08

@onready var pregame: Window = $pregame
@onready var dev: Window = $dev_menu
@onready var board: Control = $Board
@onready var players_container: Control = $Players
@onready var player_top: Control = $Players/PlayerTop
@onready var player_bottom: Control = $Players/PlayerBottom
@onready var player_left: Control = $Players/PlayerLeft
@onready var player_right: Control = $Players/PlayerRight

var is_multiplayer := false
var is_host := false
var connected_players: Array = []
var all_pieces: Array[Piece] = []
var current_player_index := 0
var board_extremes: Array = []
var game_started := false
var game_ended := false
var game_logic = [
					false,			#[0] Por la izquierda se esta jugando hacia la derecha
					false,			#[1] Por la derecha se esta jugando hacia la izquierda
					false,			#[2] Pieza que empieza el sentido contrario de game_logic[0]
					false,			#[3] Pieza que empieza el sentido contrario de game_logic[1]
					true,			#[4] Si en la esquina se puede poner un doble por la izquierda
					true,			#[5] Si en la esquina se puede poner un doble por la derecha
					false,			#[6] Auxiliar que dice si ya pusieron doble por la izquierda
					false			#[7] Auxiliar que dice si ya pusieron doble por la derecha
]

func _ready():
	randomize()
	await get_tree().process_frame
	
	if not is_multiplayer:
		print('lo puso:' , multiplayer.get_unique_id())
		pregame.visible = true
		pregame.play_pressed.connect(on_play_pressed)
		pregame.active_dev.connect(show_dev_menu)
	else:
		pregame.visible = false

func show_dev_menu():
	dev.visible = true
	dev.dev_add.connect(dev_added)

func dev_added(l, r, p):
	#print(l,r,p)
	var player = get_player_by_index(p)
	var piece = preload("res://scenes/piece.tscn").instantiate()
	piece.set_values(l, r, piece_scale)
	player.add_piece(piece)
	player.reorganize_pieces()

func set_multiplayer_info(peer, host_flag):
	is_multiplayer = peer != null
	is_host = host_flag

func set_connected_players(players: Array):
	connected_players = players
	if is_host:
		print("Jugadores conectados recibidos: ", connected_players)

# Comienza una partida
func on_play_pressed():
	if not is_multiplayer:
		setup_pieces()
		setup_players()
		start_game()
	elif is_host:
		setup_pieces()
		setup_players()
		set_meta("clients_ready", 1)
	else:
		create_players()
		position_players()
		print("Cliente listo, notificando al host...")
		rpc_id(1, "client_ready", multiplayer.get_unique_id())

# El host recibe la notificación de clientes listos
@rpc("any_peer", "reliable")
func client_ready(client_id: int):
	if is_host:
		print("Cliente ", client_id, " está listo")
		
		var clients_ready = get_meta("clients_ready", 0) + 1
		set_meta("clients_ready", clients_ready)
		
		var total_players = connected_players.size()
		print("Jugadores listos: ", clients_ready, "/", total_players)
		
		# Cuando todos estén listos, distribuir manos
		if clients_ready >= total_players:
			print("Todos listos! Distribuyendo manos...")
			distribute_hands_multiplayer()

# Prepara los jugadores
func setup_players():
	create_players()
	position_players()
	deal_pieces()

# Prepara los jugadores
func setup_pieces():
	generate_all_pieces()
	all_pieces.shuffle()

# Crea la escena de cada jugador
func create_players():
	var player_scene = preload("res://scenes/player.tscn")
	var players = [
		{"node": player_top, "name": "Top", "ai": !Global.players and !is_multiplayer, "vertical": false, "reversed": false, "enabled": true, "peer_id": -1, "position": 0},
		{"node": player_right, "name": "Right", "ai": !Global.players and !is_multiplayer, "vertical": true, "reversed": true, "enabled": Global.amount > 2, "peer_id": -1, "position": 1},
		{"node": player_bottom, "name": "Bottom", "ai": !Global.players and !Global.playing and !is_multiplayer, "vertical": false, "reversed": true, "enabled": true, "peer_id": multiplayer.get_unique_id(), "position": 2},
		{"node": player_left, "name": "Left", "ai": !Global.players and !is_multiplayer, "vertical": true, "reversed": false, "enabled": Global.amount > 2, "peer_id": -1, "position": 3}
	]

	for p in players:
		if !p["enabled"]:
			continue
		var player = player_scene.instantiate()
		player.name = "Player" + p["name"]
		player.ai = p["ai"]
		
		if connected_players.size() > p["position"]:
			player.peer_id = connected_players[p["position"]]
		else:
			player.peer_id = -1
			
		
		
		player.piece_spacing = piece_spacing
		player.vertical = p["vertical"]
		player.reversed = p["reversed"]
		player.hand_visible = player.peer_id == multiplayer.get_unique_id() 
		p["node"].add_child(player)
		player.piece_played.connect(_on_piece_played)
		player.piece_pressed.connect(_on_piece_pressed)
		player.turn_passed.connect(change_turn)

# Posiciona a cada jugador
func position_players():
	var viewport_size = get_viewport_rect().size
	margin = min(viewport_size.x, viewport_size.y) * 0.05

	player_top.position = Vector2(viewport_size.x/2, margin)
	player_top.size = Vector2(length, width)
	
	player_bottom.position = Vector2(viewport_size.x/2, viewport_size.y - margin)
	player_bottom.size = Vector2(length, width)
	
	player_left.position = Vector2(margin, viewport_size.y/2)
	player_left.size = Vector2(width, length)
	
	player_right.position = Vector2(viewport_size.x - margin, viewport_size.y/2)
	player_right.size = Vector2(width, length)
	
	player_left.pivot_offset = Vector2(player_left.size.x/2, player_left.size.y/2)
	player_right.pivot_offset = Vector2(player_right.size.x/2, player_right.size.y/2)

# Establece el cuadro de la mano
func configure_player_container(container: Control, player_position: String):
	container.custom_minimum_size = Vector2(length, width)

	match player_position:
		"top":
			container.anchor_top = 0.0
			container.anchor_left = 0.3
			container.anchor_right = 0.7
			container.anchor_bottom = 0.1
			container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		"bottom":
			container.anchor_top = 0.9
			container.anchor_left = 0.3
			container.anchor_right = 0.7
			container.anchor_bottom = 1.0
			container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		"left":
			container.anchor_top = 0.3
			container.anchor_left = 0.0
			container.anchor_right = 0.1
			container.anchor_bottom = 0.7
			container.grow_vertical = Control.GROW_DIRECTION_BOTH
		"right":
			container.anchor_top = 0.3
			container.anchor_left = 0.9
			container.anchor_right = 1.0
			container.anchor_bottom = 0.7
			container.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	container.offset_top = 0
	container.offset_left = 0
	container.offset_right = 0
	container.offset_bottom = 0

# Crea las piezas
func generate_all_pieces():		
	for left in range(7):
		for right in range(left, 7):
			var piece = preload("res://scenes/piece.tscn").instantiate()
			piece.set_values(left, right, piece_scale)
			piece.id = "%d-%d" % [left, right]
			all_pieces.append(piece)

# Reparte la piezas
func deal_pieces():				
	if multiplayer:
		return
	var player_configs = [
		{"node": player_top},
		{"node": player_right},
		{"node": player_bottom},
		{"node": player_left}
	]
	
	for i in range(total_players):
		var config = player_configs[i]
		var player = config["node"].get_child(0) as Player
		
		if not player:
			push_error("Jugador no encontrado en ", config["node"].name)
			continue
			
		for j in range(pieces_per_player):
			if all_pieces.is_empty():
				push_error("No hay suficientes fichas")
				return
				
			var piece = all_pieces.pop_back()
			player.add_piece(piece)
	
		player.reorganize_pieces()

# Comienza el juego
func start_game():
	game_started = true
	current_player_index = randi() % 4
	
	if Global.amount == 2:
		if current_player_index == 1 || current_player_index == 3:
			current_player_index +=1
	
	print("Turno del jugador ", current_player_index)
	begin_player_turn(current_player_index)

# Comienza el turno del jugador segun indice
func begin_player_turn(player_index: int):
	var player = get_player_by_index(player_index)
	if player:
		Global.board_extremes = board_extremes
		player.set_turn(true, board_extremes)

# Termina el turno del jugador segun indice
func end_player_turn(player_index: int):
	var player = get_player_by_index(player_index)
	if player:
		player.set_turn(false, [])

# Obtiene el jugador segun indice
func get_player_by_index(index: int) -> Node:
	var players = [
		player_top.get_child(0),
		player_left.get_child(0),
		player_bottom.get_child(0),
		player_right.get_child(0)
	]
	return players[index] if index < players.size() else null

# Cambia el turno al siguiente jugador
func change_turn():
	if game_ended:
		return
		
	var current_player = get_player_by_index(current_player_index)
	if current_player and current_player.pieces.size() == 0:
		end_game(current_player_index, true)
		return

	var next_player_index = (current_player_index + 1) % total_players
	if Global.amount == 2:
		if current_player_index == 0:
			next_player_index = 2
		else:
			next_player_index = 0
	
	var players_checked = 0
	var can_anyone_play = false

	while players_checked < total_players:
		var player = get_player_by_index(next_player_index)
		if player and player.can_play(board_extremes[0], board_extremes[3]):
			can_anyone_play = true
			break
		next_player_index = (next_player_index + 1) % total_players
		players_checked += 1

	if not can_anyone_play:
		end_game(-1, false)
		return
	
	print(current_player_index)
	print(next_player_index)
	end_player_turn(current_player_index)
	current_player_index = next_player_index
	begin_player_turn(current_player_index)

# Finaliza el juego
func end_game(winning_player_index: int, by_empty_hand: bool):		
	game_ended = true

	if by_empty_hand:
		var winner = get_player_by_index(winning_player_index)
		show_game_over_message("¡Ganador: " + winner.name + "!\n(Se quedó sin fichas)")
	else:
		var min_points = INF
		var winners = []
		var points_report = ""

		for i in range(total_players):
			var player = get_player_by_index(i)
			if player:
				var points = player.calculate_hand_points()
				points_report += player.name + ": " + str(points) + " puntos\n"

				if points < min_points:
					min_points = points
					winners = [i]
				elif points == min_points:
					winners.append(i)

		if winners.size() == 1:
			var winner = get_player_by_index(winners[0])
			show_game_over_message(
				"¡Juego bloqueado!\n\n" + 
				points_report + "\n" +
				"Ganador: " + winner.name + "\n" +
				"(Menos puntos: " + str(min_points) + ")"
			)
		else:
			var winners_names = ""
			for winner_index in winners:
				winners_names += get_player_by_index(winner_index).name + ", "
			winners_names = winners_names.rstrip(", ")

			show_game_over_message(
				"¡Juego bloqueado!\n\n" + 
				points_report + "\n" +
				"Empate entre: " + winners_names + "\n" +
				"(Puntos: " + str(min_points) + ")"
			)

	for i in range(total_players):
		end_player_turn(i)

# Muestra la pantalla de juego terminado
func show_game_over_message(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Fin del Juego"
	popup.size = Vector2(400, 300)
	add_child(popup)
	popup.popup_centered()

	popup.get_ok_button().text = "Jugar de nuevo"
	popup.confirmed.connect(_on_play_again_pressed)

# Reinicia el juego
func _on_play_again_pressed():
	get_tree().reload_current_scene()

# Juega la pieza y pasa el turno al siguiente
func _on_piece_played(piece: Piece, type: String):
	var transform = piece_on_board(piece, type, true)
	piece.position = transform.position
	piece.rotation_degrees = transform.rotation
	piece.front.visible = true
	piece.back.visible = false
	
	board.add_child(piece)
	update_board_extremes(piece, type)
	change_turn()

# Coloca los Sprites en la posiciones sugeridas
func _on_piece_pressed(piece: Piece):
	var possible_types = piece_on_board_unbound(piece)
	var back_scene = preload("res://scenes/back.tscn")

	for t in possible_types:
		var ref_sprite = back_scene.instantiate()
		ref_sprite.name = "ref_" + t
		var sprite_node = ref_sprite.get_node("Sprite2D")
		sprite_node.scale = piece.back.scale
		sprite_node.centered = piece.back.centered

		var transform = piece_on_board(piece, t)
		ref_sprite.position = transform.position
		sprite_node.rotation_degrees = transform.rotation

		ref_sprite.set_meta("piece", piece)
		ref_sprite.set_meta("position_type", t)
		add_child(ref_sprite)
		ref_sprite.add_to_group("possibility_areas")

# Calcula la posicion de la pieza
func piece_on_board(piece: Piece, type: String, update_flags = false) -> Dictionary:
	var result = {"position": Vector2(), "rotation": 0}
	var base_piece: Piece

	if type in ['D', 'N']:
		result.position = board.size / 2 - piece.size / 2
		result.rotation = 0 if type == 'D' else -90
		return result

	if type in ['RR', 'RL', 'RD']:
		base_piece = board_extremes[2]
		if base_piece.left == base_piece.right or piece.left == piece.right:
			if game_logic[7]:
				if update_flags:
					game_logic[7] = false
				result.position = base_piece.position - Vector2(base_piece.size.y, 0)
			elif not game_logic[1]:
				result.position = base_piece.position + Vector2(piece.size.x / 2 + base_piece.size.x, 0)
			else:
				if not game_logic[3]:
					result.position = base_piece.position - Vector2(piece.size.x / 2 + base_piece.size.x, 0)
				else:
					if update_flags:
						game_logic[3] = false
						game_logic[7] = true
					
					result.position = base_piece.position + Vector2(piece.size.x / 2 + base_piece.size.x, 0)
		else:
			if game_logic[3]:
				if type == "RD":
					result.position = base_piece.position + Vector2(0 , piece.size.y * 3 / 4)
				else:
					result.position = base_piece.position + Vector2(-piece.size.y * 1 / 4 , piece.size.y * 3 / 4)
				if update_flags:
					game_logic[3] = false
					game_logic[5] = false
			elif game_logic[1]:
				result.position = piece_left_direction(base_piece, piece)
			else:
				result.position = piece_right_direction(base_piece, piece)
		
		if not game_logic[1]:
			if type == 'RR' or type == 'N':
				result.rotation = 90
			elif type == 'RL':
				result.rotation = -90
			elif type == 'RD':
				result.rotation = 0
		else:
			if type == 'RL':
				result.rotation = 90
			elif type == 'RR':
				result.rotation = -90
			elif type == 'RD':
				result.rotation = 0

	elif type in ['LL', 'LR', 'LD']:
		base_piece = board_extremes[1]
		if base_piece.left == base_piece.right or piece.left == piece.right:
			if game_logic[6]:
				if update_flags:
					game_logic[6] = false
				result.position = base_piece.position + Vector2(base_piece.size.y, 0)
			elif not game_logic[0]:
				result.position = base_piece.position - Vector2(piece.size.x / 2 + base_piece.size.x, 0)
			else:
				if not game_logic[2]:
					result.position = base_piece.position + Vector2(piece.size.x / 2 + base_piece.size.x, 0)
				else:
					if update_flags:
						game_logic[2] = false
						game_logic[6] = true
					
					result.position = base_piece.position - Vector2(piece.size.x / 2 + base_piece.size.x, 0)
		else:
			if game_logic[2]:
				if type == "LD":
					result.position = base_piece.position - Vector2(-piece.size.x, piece.size.y * 3 / 4)
				else:
					result.position = base_piece.position - Vector2(-piece.size.x/2, piece.size.y * 3 / 4)
				if update_flags:
					game_logic[2] = false
					game_logic[4] = false
					
			elif game_logic[0]:
				result.position = piece_right_direction(base_piece, piece)
			else:
				result.position = piece_left_direction(base_piece, piece)

		if not game_logic[0]:
			if type == 'LL':
				result.rotation = 90
			elif type == 'LR':
				result.rotation = -90
			elif type == 'LD':
				result.rotation = 0
		else: 
			if type == 'LR':
				result.rotation = 90
			elif type == 'LL':
				result.rotation = -90
			elif type == 'LD':
				result.rotation = 0
	
	return limit_check(result, piece, base_piece, type, update_flags)

# Comprueba que se juegue en los limites
func limit_check(result, piece, base_piece, type, update_flags):
	var viewport_size = get_viewport_rect().size
	var margin_x = viewport_size.x * 0.15
	var min_x = margin_x
	var max_x = viewport_size.x - margin_x

	if result.position.x - piece.size.x/2 < min_x and not type == "LD":
		if base_piece.left == base_piece.right or piece.left == piece.right:
			result.position = base_piece.position - Vector2(0, piece.size.y)
		else:
			result.position = base_piece.position - Vector2(piece.size.x / 2, piece.size.y * 3 / 4)
		
		if type == "LR":
			result.rotation = 0
		elif type == "LL":
			result.rotation = 180
		
		if update_flags:
			game_logic[2] = true
			if type in ["RR", "RL", "RD"]:
				game_logic[1] = not game_logic[1]
			elif type in ["LL", "LR", "LD"]:
				game_logic[0] = not game_logic[0]
			
	elif result.position.x + piece.size.x/2 > max_x and not type == "RD":
		if base_piece.left == base_piece.right or piece.left == piece.right:
			result.position = base_piece.position + Vector2(0, piece.size.y)
		else:
			result.position = base_piece.position + Vector2(piece.size.x / 2, piece.size.y * 3 / 4)

		if type == "RR":
			result.rotation = 180
		elif type == "RL":
			result.rotation = 0
		
		if update_flags:
			game_logic[3] = true
			if type in ["RR", "RL", "RD"]:
				game_logic[1] = not game_logic[1]
			elif type in ["LL", "LR", "LD"]:
				game_logic[0] = not game_logic[0]
	elif type == "LD" and game_logic[0] and game_logic[4]:
		if update_flags:
			game_logic[4] = false
		result.position = base_piece.position - Vector2(0, piece.size.y * 3 / 4)
		result.rotation = 90
	elif type == "RD" and game_logic[1] and game_logic[5]:
		if update_flags:
			game_logic[5] = false
		result.position = base_piece.position + Vector2(0, piece.size.y * 3 / 4)
		result.rotation = 90
	return result

func piece_right_direction(base_piece, piece):
	var result = base_piece.position + Vector2(piece.size.x + base_piece.size.x, 0)
	return result

func piece_left_direction(base_piece, piece):
	var result = base_piece.position - Vector2(piece.size.x + base_piece.size.x, 0)
	return result

# Calcula las posibles posiciones de la pieza
func piece_on_board_unbound(piece: Piece):
	var posib = []
	if board_extremes.is_empty():
		if piece.left == piece.right:
			posib.append('D')
		else:
			posib.append('N')
	else:
		if piece.left == piece.right and board_extremes[0] == piece.left:
			posib.append('LD')
		if piece.left == piece.right and board_extremes[3] == piece.right:
			posib.append('RD')
		if board_extremes[0] == piece.left and piece.left != piece.right:
			posib.append('LL')
		if board_extremes[0] == piece.right and piece.left != piece.right:
			posib.append('LR')
		if board_extremes[3] == piece.right and piece.left != piece.right:
			posib.append('RR')
		if board_extremes[3] == piece.left and piece.left != piece.right:
			posib.append('RL')
	
	return posib

# Actualiza los extremos del tablero
func update_board_extremes(piece: Piece, type: String):
	if board_extremes.is_empty() or type == 'D' or type == 'N':
		board_extremes = [piece.left, piece, piece, piece.right]
	elif type == 'LL' or type == 'LR' or type == 'LD':
		if type == 'LR':
			board_extremes[0] = piece.left
		else:
			board_extremes[0] = piece.right
		board_extremes[1] = piece
	elif type == 'RR' or type == 'RL' or type == 'RD':
		if type == 'RL':
			board_extremes[3] = piece.right
		else:
			board_extremes[3] = piece.left
		board_extremes[2] = piece

# Notificaciones
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		adjust_layout()

# Ajusta la pantalla
func adjust_layout():
	pass

func seed_random_number_generator(seed_value: int):
	seed(seed_value)

@rpc("any_peer", "reliable")
func rpc_play_piece(id: String, type: String):
	var piece = find_piece(id)
	if piece:
		_on_piece_played(piece, type)
	else:
		print("❌ No se encontró la pieza con id: %s" % id)

func find_piece(id: String) -> Piece:
	for player in $Players.get_children():
		for piece in player.pieces:
			if piece.piece_id == id:
				return piece
	return null
	
# Recibe un nodo Player y una lista de IDs de piezas
func assign_hand_to_player(player: Player, piece_ids: Array):
	
	for id in piece_ids:
		var piece_found = false

		for piece in all_pieces:
			if piece.id == id:
				player.add_piece(piece)
				piece_found = true
				if is_host:
					all_pieces.erase(piece)
				break
		
		if not piece_found:
			var parts = id.split("-")
			if parts.size() == 2:
				var left = int(parts[0])
				var right = int(parts[1])
				var new_piece = preload("res://scenes/piece.tscn").instantiate()
				new_piece.set_values(left, right, piece_scale)
				new_piece.id = id
				player.add_piece(new_piece)
	
	print("Fichas asignadas al jugador ", player.peer_id, " en id ", multiplayer.get_unique_id())

# Host: reparte las manos y las envía a los clientes
func distribute_hands_multiplayer():
	if not is_host:
		return
	
	print("Distribuyendo manos para ", connected_players.size(), " jugadores...")
	
	# Pequeña espera para que los clientes se inicialicen
	await get_tree().create_timer(0.5).timeout
	
	var players = get_all_players()
	var all_hands_data: Dictionary = {}
	
	for player in players:
		var hand_ids: Array = []
		for j in range(pieces_per_player):
			if all_pieces.is_empty():
				break
			var piece = all_pieces.pop_back()
			hand_ids.append(piece.id)

			player.add_piece(piece)

		all_hands_data[player.peer_id] = hand_ids
		print("Mano para peer ", player.peer_id, ": ", hand_ids)

	print("📤 Enviando las manos a todos los clientes...")
	set_meta("hands_received_count", 1)
	rpc("_receive_all_hands", all_hands_data)
	

func get_all_players() -> Array[Player]:
	var players: Array[Player] = []
	var containers = [player_top, player_right, player_bottom, player_left]
	
	for container in containers:
		if container.get_child_count() > 0:
			var player = container.get_child(0) as Player
			if player:
				players.append(player)
	
	return players

# Cliente: recibe las manos asignadas
@rpc("any_peer", "reliable")
func _receive_all_hands(all_hands_data: Dictionary):
	var my_id = multiplayer.get_unique_id()
	print("Cliente ", my_id, " recibió todas las manos: ", all_hands_data.keys())

	for player in get_all_players():
		player.get_multiplayer_id()
		assign_hand_to_player(player, all_hands_data[player.get_multiplayer_id()])
		player.reorganize_pieces()
	
	Global.all_players_hands = all_hands_data.duplicate()
	print("Cliente ", my_id, " confirmando recepción de manos al host")
	rpc_id(1, "confirm_hands_received", my_id)
	
@rpc("any_peer", "reliable")
func confirm_hands_received(client_id: int):
	if is_host:
		var received_count = get_meta("hands_received_count", 0) + 1
		set_meta("hands_received_count", received_count)
		var total_players = connected_players.size()

		if received_count >= total_players:
			print("✅ Todas las manos recibidas! Iniciando juego...")
			start_game()
