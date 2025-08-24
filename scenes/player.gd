class_name Player
extends Node2D

signal piece_played(piece, type)
signal piece_pressed(piece, type)
signal turn_passed

@export var ai: bool = false
@export var hand_visible: bool = true
@export var piece_spacing: float = 60
@export var vertical: bool = false
@export var reversed: bool = false


@onready var hand: Node2D = $Hand

var pieces: Array[Piece] = []
var turn: bool = false
var piece_selected: Piece = null

func _ready():
	update_pieces_visibility()
	
func _input(event):						#Acciones del jugador (seleccionar pieza)
	if not ai and event is InputEventMouseButton and turn:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var rised = false
			
			for piece in pieces:
				var piece_global_pos = piece.global_position
				var piece_rect = Rect2(piece_global_pos - piece.size/2, piece.size)
				
				if piece_rect.has_point(mouse_pos):
					if piece_selected:
						piece_selected.decrease()
						clear_possibility_areas()
					piece.increase()
					var type = calculate_type(piece,Global.board_extremes)
					emit_signal("piece_pressed", piece, type)
					piece_selected = piece
					rised = true
					break
			if !rised and piece_selected:
				piece_selected.decrease()
				clear_possibility_areas()
				piece_selected = null

# Eliminar todos los sprites del grupo
func clear_possibility_areas():
	get_tree().call_group("possibility_areas", "queue_free")

func update_pieces_visibility():		#Establece q cara es visible
	for piece in pieces:
		piece.get_node("Front").visible = hand_visible
		piece.get_node("Back").visible = not hand_visible

func add_piece(piece: Piece):			#Añade pieza a la mano del jugador
	pieces.append(piece)
	hand.add_child(piece)
	piece.position = Vector2(pieces.size() * piece_spacing, 0)
	update_pieces_visibility()

func reorganize_pieces():				#Reorganiza las piezas de la mano del jugador
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

func set_turn(state: bool, board_extremes: Array):		#Comienza el turno del jugador
	turn = state
	if turn and ai:
		ai_turn(board_extremes)
	elif turn and !ai:
		pass
		#print(board_extremes)

func ai_turn(board_extremes: Array):					#Comienza el turno de la IA
	var possible = []
	
	for piece in pieces:
		var type = calculate_type(piece, board_extremes)
		possible.append([piece,type])
		
	if possible.is_empty():
		emit_signal("turn_passed")
	else:
		var p = select_piece(possible)
		play_piece(p[0], p[1])

func calculate_type(piece: Piece, board_extremes):		#Calcula el tipo de la pieza
	if board_extremes.is_empty():
		if piece.left == piece.right:
			return 'D'
		else:
			return 'N'
	else:
		if piece.left == piece.right and board_extremes[0] == piece.left:
			return 'LD'
		if piece.left == piece.right and board_extremes[3] == piece.right:
			return 'RD'
		if board_extremes[0] == piece.left and piece.left != piece.right:
			return 'LL'
		if board_extremes[0] == piece.right and piece.left != piece.right:
			return 'LR'
		if board_extremes[3] == piece.right and piece.left != piece.right:
			return 'RR'
		if board_extremes[3] == piece.left and piece.left != piece.right:
			return 'RL'
	return 'I'

func select_piece(possible: Array) -> Array:			#Algoritmo para seleccion de la IA 
	var weights = {
		'RD': 1.0,
		'RR': 1.0,
		'RL': 1.0,
		'LD': 1.0,
		'LL': 1.0,
		'LR': 1.0,
		'D': 2.5,
		'N': 0.2,
		'I': 0
	}
	
	for i in range(possible.size()):
		possible[i].append(randf() * weights[possible[i][1]])
	
	var max = possible[0]
	for e in possible:
		if e[2] > max[2]:
			max = e

	return max

func play_piece(piece: Piece, type: String):			#Juega la pieza seleccionada
	await get_tree().create_timer(1.0).timeout
	if piece in pieces:
		pieces.erase(piece)
		hand.remove_child(piece)
		emit_signal("piece_played", piece, type)
		reorganize_pieces()

func calculate_hand_points() -> int:					#Calcula los puntos en caso de empate
	var total = 0
	for piece in pieces:
		total += piece.left + piece.right
	return total

func can_play(left_value: int, right_value: int) -> bool:		#calcula si el jugador tiene algun movimiento valido
	for piece in pieces:
		if piece.left == left_value or piece.right == left_value or \
		   piece.left == right_value or piece.right == right_value:
			return true
	return false
