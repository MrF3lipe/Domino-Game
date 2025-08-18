class_name Player
extends Node2D

signal piece_played(piece, type)
signal turn_passed

@export var ai: bool = false
@export var hand_visible: bool = true
@export var vertical: bool = false
@export var reversed: bool = false

@onready var hand: Node2D = $Hand

var pieces: Array[Piece] = []
var turn: bool = false
var piece_spacing

func _ready():
	update_pieces_visibility()

func update_pieces_visibility():
	for piece in pieces:
		piece.get_node("Front").visible = hand_visible
		piece.get_node("Back").visible = not hand_visible

func add_piece(piece: Piece):
	pieces.append(piece)
	hand.add_child(piece)
	piece.position = Vector2(pieces.size() * piece.piece_scale, 0)
	update_pieces_visibility()

func reorganize_pieces():
	piece_spacing = pieces[0].piece_scale
	for i in range(pieces.size()):
		if vertical:
			var y_pos = i * piece_spacing
			if reversed:
				y_pos = -y_pos  
			pieces[i].position = Vector2(0, y_pos)
			pieces[i].rotation_degrees = 90  
		else:
			pieces[i].position = Vector2(i * piece_spacing, 0)
			pieces[i].rotation_degrees = 0

func set_turn(state: bool, board_extremes: Array):
	turn = state
	if turn and ai:
		ai_turn(board_extremes)

func ai_turn(board_extremes: Array):
	if not ai or not turn:
		return
	var possible = []
	
	for piece in pieces:
		if piece.left == piece.right and board_extremes.is_empty():
			possible.append([piece, 'D'])
		elif board_extremes.is_empty():
			possible.append([piece, 'N'])
		else:
			if piece.left == piece.right and board_extremes[0] == piece.left:
				possible.append([piece, 'LD'])

			if piece.left == piece.right and board_extremes[3] == piece.right:
				possible.append([piece, 'RD'])

			if board_extremes[0] == piece.left and piece.left != piece.right:
				possible.append([piece, 'LL'])
			
			if board_extremes[0] == piece.right and piece.left != piece.right:
				possible.append([piece, 'LR'])
				
			if board_extremes[3] == piece.right and piece.left != piece.right:
				possible.append([piece, 'RR'])
			
			if board_extremes[3] == piece.left and piece.left != piece.right:
				possible.append([piece, 'RL'])

	if possible.is_empty():
		emit_signal("turn_passed")
	else:
		var p = select_piece(possible)
		play_piece(p[0], p[1])

func select_piece(possible: Array) -> Array:
	var weights = {
		'RD': 1.0,
		'RR': 1.0,
		'RL': 1.0,
		'LD': 1.0,
		'LL': 1.0,
		'LR': 1.0,
		'D': 2.5,
		'N': 0.2
	}
	
	for i in range(possible.size()):
		possible[i].append(randf() * weights[possible[i][1]])
	
	var max = possible[0]
	for e in possible:
		if e[2] > max[2]:
			max = e

	return max

func play_piece(piece: Piece, type: String):
	await get_tree().create_timer(1.0).timeout
	if piece in pieces:
		pieces.erase(piece)
		hand.remove_child(piece)
		emit_signal("piece_played", piece, type)
		reorganize_pieces()

func calculate_hand_points() -> int:
	var total = 0
	for piece in pieces:
		total += piece.left + piece.right
	return total

func can_play(left_value: int, right_value: int) -> bool:
	for piece in pieces:
		if piece.left == left_value or piece.right == left_value or \
		   piece.left == right_value or piece.right == right_value:
			return true
	return false
