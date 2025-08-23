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
	#area.input_pickable = true
	load_piece()
	
	#area.connect("input_event", _on_area_2d_input_event)
	#area.connect("mouse_entered", _on_area_2d_mouse_entered)
	#area.connect("mouse_exited", _on_area_2d_mouse_exited)

func load_piece():
	front.texture = load("res://textures/%d-%d B.png" % [left, right])
	front.scale = Vector2(piece_scale, piece_scale)
	
	back.texture = load("res://textures/B.png" % [left, right])
	back.scale = Vector2(piece_scale, piece_scale)

func set_values(l = left, r = right, s = piece_scale):
	left = l
	right = r
	piece_scale = s

#func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton:
		#if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			#selected = true
			#print(left, ':', right)
#
#func _on_area_2d_mouse_entered() -> void:
	#increase()
	#print('in')
#
#func _on_area_2d_mouse_exited() -> void:
	#decrease()
	#print('out')
#
func increase():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func decrease():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
