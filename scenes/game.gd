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
var playing = true

func _ready():
	randomize()
	#get_window().min_size = Vector2(800, 800)
	#get_window().size = Vector2(800, 800)
	
	await get_tree().process_frame
	play_pressed()

func play_pressed():
	
	setup_pieces()
	setup_players()
	start_game()

func setup_players():
	create_players()
	position_players()
	deal_pieces()

func setup_pieces():
	generate_all_pieces()
	shuffle_pieces()

func create_players():
	var player_scene = preload("res://scenes/player.tscn")
	var players = [
		{"node": player_top, "name": "Top", "ai": true, "vertical": false, "reversed": false},
		{"node": player_right, "name": "Right", "ai": true, "vertical": true, "reversed": true},
		{"node": player_bottom, "name": "Bottom", "ai": !playing, "vertical": false, "reversed": true},
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
		player.turn_passed.connect(change_turn)

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

func generate_all_pieces():
	for left in range(7):
		for right in range(left, 7):
			var piece = preload("res://scenes/piece.tscn").instantiate()
			piece.set_values(left, right, piece_scale)
			all_pieces.append(piece)

func shuffle_pieces():
	all_pieces.shuffle()

func start_game():
	game_started = true
	current_player_index = randi() % 4
	begin_player_turn(current_player_index)

func begin_player_turn(player_index: int):
	var player = get_player_by_index(player_index)
	if player:
		player.set_turn(true, board_extremes)

func end_player_turn(player_index: int):
	var player = get_player_by_index(player_index)
	if player:
		player.set_turn(false, [])

func get_player_by_index(index: int) -> Node:
	var players = [
		player_top.get_child(0),
		player_left.get_child(0),
		player_bottom.get_child(0),
		player_right.get_child(0)
	]
	return players[index] if index < players.size() else null

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

func show_game_over_message(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Fin del Juego"
	popup.size = Vector2(400, 300)
	add_child(popup)
	popup.popup_centered()

	popup.get_ok_button().text = "Jugar de nuevo"
	popup.confirmed.connect(_on_play_again_pressed)

func _on_play_again_pressed():
	get_tree().reload_current_scene()

func _on_piece_played(piece: Piece, type: String):
	board.add_child(piece)
	piece.front.visible = true
	piece.back.visible = false
	piece_on_board(piece, type)
	update_board_extremes(piece, type)
	change_turn()

func piece_on_board(piece: Piece, type: String):
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
	
	if type == 'D':
		piece.position = piece_position
	elif type == 'N':
		piece.position = piece_position
		piece.rotation_degrees = 90
	elif type == 'RR':
		piece.position = piece_position
		piece.rotation_degrees = 90
	elif type == 'RL':
		piece.position = piece_position
		piece.rotation_degrees = -90
	elif type == 'LL':
		piece.position = piece_position
		piece.rotation_degrees = 90
	elif type == 'LR':
		piece.position = piece_position
		piece.rotation_degrees = -90
	elif type == 'RD':
		piece.position = piece_position
		piece.rotation_degrees = 0
	elif type == 'LD':
		piece.position = piece_position
		piece.rotation_degrees = 0
	
	#debug_visual(piece, type, base_piece, piece_position)

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

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		adjust_layout()

func adjust_layout():
	pass
