class_name Game
extends Control

@export var total_players := 4
@export var pieces_per_player := 7
@export var margin := 0.05
@export var piece_spacing := 50
@export var length = 300
@export var width = 100
@export var piece_scale = 0.1

@onready var board: Control = $Board
@onready var players_container: Control = $Players
@onready var player_top: Control = $Players/PlayerTop
@onready var player_bottom: Control = $Players/PlayerBottom
@onready var player_left: Control = $Players/PlayerLeft
@onready var player_right: Control = $Players/PlayerRight

var all_pieces: Array[Piece] = []
var current_player_index := 0
var board_extremes: Array = []
var game_started := false
var game_ended := false

func _ready():
	randomize()
	await get_tree().process_frame
	play_pressed()

# Comienza una partida
func play_pressed():
	setup_pieces()
	setup_players()
	start_game()

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
		{"node": player_top, "name": "Top", "ai": true, "vertical": false, "reversed": false},
		{"node": player_right, "name": "Right", "ai": true, "vertical": true, "reversed": true},
		{"node": player_bottom, "name": "Bottom", "ai": !Global.playing, "vertical": false, "reversed": true},
		{"node": player_left, "name": "Left", "ai": true, "vertical": true, "reversed": false}
	]

	for p in players:
		var player = player_scene.instantiate()
		player.name = "Player" + p["name"]
		player.ai = p["ai"]
		player.piece_spacing = piece_spacing
		player.vertical = p["vertical"]
		player.reversed = p["reversed"]
		player.hand_visible = not p["ai"]
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
			all_pieces.append(piece)

# Reparte la piezas
func deal_pieces():				
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
	piece.front.visible = true
	board.add_child(piece)
	piece.back.visible = false
	piece_on_board(piece, type)
	update_board_extremes(piece, type)
	change_turn()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			
			for possibility in get_tree().get_nodes_in_group("possibility_areas"):
				var sprite = possibility.get_node("Sprite2D")
				if sprite and sprite.texture:
					var texture_size = sprite.texture.get_size() * sprite.scale
					
					var piece_rect = Rect2(
						possibility.global_position.x - texture_size.x / 2,
						possibility.global_position.y - texture_size.y / 2,
						texture_size.x,
						texture_size.y
					)
					
					if piece_rect.has_point(mouse_pos):
						var piece = possibility.get_meta("piece")
						var type = possibility.get_meta("position_type")
						_on_piece_played(piece, type)
						break

# Coloca los Sprites en la posiciones sugeridas
func _on_piece_pressed(piece: Piece, type: String):
	var possible_type = piece_on_board_unbound(piece, type)
	var back_scene = preload("res://scenes/back.tscn")
	
	for t in possible_type:
		if t in ['RR', 'RL', 'RD']:
			var right_posibility = back_scene.instantiate()
			right_posibility.name = "right_posibility"
			
			var sprite = right_posibility.get_node("Sprite2D")
			sprite.scale = piece.back.scale
			sprite.centered = piece.back.centered
	
			right_posibility.position = piece_on_board(piece, t, true)
			if t in ['RR', 'RL']:
				sprite.rotation_degrees = 90

			right_posibility.set_meta("piece", piece)
			right_posibility.set_meta("position_type", t)
			add_child(right_posibility)
			right_posibility.add_to_group("possibility_areas")
			
			
		elif t in ['LR', 'LL', 'LD', 'D', 'N']:
			var left_posibility = back_scene.instantiate()
			left_posibility.name = "left_posibility"
			
			var sprite = left_posibility.get_node("Sprite2D")
			sprite.scale = piece.back.scale
			sprite.centered = piece.back.centered
			
			left_posibility.position = piece_on_board(piece, t, true)
			if t in ['LR', 'LL', 'N']:
				sprite.rotation_degrees = 90

			left_posibility.set_meta("piece", piece)
			left_posibility.set_meta("position_type", t)
			add_child(left_posibility)
			left_posibility.add_to_group("possibility_areas")

# Calcula la posicion de la pieza
func piece_on_board(piece: Piece, type: String, reference = false):
	var piece_position = Vector2(0, 0)
	var base_piece = null
	
	if type == 'D' or type == 'N':
		piece_position = board.size / 2 - piece.size / 2
	elif type == 'RR' or type == 'RL' or type == 'RD':
		base_piece = board_extremes[2]
		if base_piece.left == base_piece.right or piece.left == piece.right:
			piece_position = base_piece.position + Vector2(piece.size.x / 2 + base_piece.size.x, 0)
		else:
			piece_position = base_piece.position + Vector2(piece.size.x + base_piece.size.x, 0)
	elif type == 'LR' or type == 'LL' or type == 'LD':
		base_piece = board_extremes[1]
		if base_piece.left == base_piece.right or piece.left == piece.right:
			piece_position = base_piece.position - Vector2(piece.size.x / 2 + base_piece.size.x, 0)
		else:
			piece_position = base_piece.position - Vector2(piece.size.x + base_piece.size.x, 0)
	
	if reference == false:
		piece.position = piece_position
	
		if type=='D':
			piece.rotation_degrees = 0
		elif type=='N' or type=='RR' or type=='LL':
			piece.rotation_degrees = 90
		elif type =='RL' or type=='LR':
			piece.rotation_degrees = -90
	else:
		return piece_position
	
	#debug_visual(piece, type, base_piece, piece_position)

# Calcula las posibles posiciones de la pieza
func piece_on_board_unbound(piece: Piece, type: String):
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

func debug_visual(piece: Piece, type: String, base_piece: Piece, piece_position: Vector2):
	if type != 'D' and type != 'N':
		print("\nCálculo de posición: ", str(piece.left), " : ", str(piece.right),
		"\nTipo: ", type,
		"\nBase: ", str(base_piece.left), " : ", str(base_piece.right),
		"\nPieza base pos: ", str(base_piece.position),
		"\nTamaño base: ", str(base_piece.size),
		"\nRotación base: ", str(base_piece.rotation_degrees),
		"\nRecorrido en x: ", str(piece.size.x + base_piece.size.x),
		"\nPosición final: ", piece_position, " ", str(piece.rotation_degrees))

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
