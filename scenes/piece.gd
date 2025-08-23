class_name Piece
extends Node2D

@export var left: int = 0
@export var right: int = 5

@onready var front: Sprite2D = $Front
@onready var back: Sprite2D = $Back
@onready var area: Area2D = $Area2D

var piece_scale = 0.07

var size: Vector2:
	get:
		if front and front.texture:
			return front.texture.get_size() * piece_scale
		return Vector2(50, 100)

func _ready():
	load_piece()

func load_piece():		#Carga una pieza segun sus valores
	
	if left==-1:
		front.texture = load("res://textures/B.png")
		front.scale = Vector2(piece_scale, piece_scale)
		
		back.texture = load("res://textures/B.png")
		back.scale = Vector2(piece_scale, piece_scale)
	
	else:
		front.texture = load("res://textures/%d-%d B.png" % [left, right])
		front.scale = Vector2(piece_scale, piece_scale)
		
		back.texture = load("res://textures/B.png" % [left, right])
		back.scale = Vector2(piece_scale, piece_scale)

func set_values(l = left, r = right, s = piece_scale):		#actualiza los valores de la pieza
	left = l
	right = r
	piece_scale = s

func increase():			#incrementa el tamaño
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func decrease():			#Disminuye el tamaño
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
