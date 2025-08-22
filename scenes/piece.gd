class_name Piece
extends Node2D

@export var left: int = 0
@export var right: int = 5

@onready var front: Sprite2D = $Front
@onready var back: Sprite2D = $Back
@onready var area: Area2D = $Area2D

var piece_scale = 0.07

signal piece_pressed(left,right)

var size: Vector2:
	get:
		if front and front.texture:
			return front.texture.get_size() * piece_scale
		return Vector2(50, 100)

func _ready():
	self.connect("MOUSE_BUTTON_LEFT",pressed)
	load_piece()

func load_piece():
	front.texture = load("res://textures/%d-%d B.png" % [left, right])
	front.scale = Vector2(piece_scale, piece_scale)
	
	back.texture = load("res://textures/B.png" % [left, right])
	back.scale = Vector2(piece_scale, piece_scale)

func pressed():
	piece_pressed.emit(left,right)

func dbg(a):
	print(a)

func set_values(l = left, r = right, s = piece_scale):
	left = l
	right = r
	piece_scale = s
