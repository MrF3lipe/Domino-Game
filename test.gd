extends Node2D

@onready var piece_scene = preload("res://scenes/piece.tscn")

func _ready():
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2
	
	# Crear varias fichas para probar
	var test_pieces = [
		{"values": [0, 0], "pos": center + Vector2(-100, 0)},
		{"values": [3, 4], "pos": center},
		{"values": [6, 6], "pos": center + Vector2(100, 0)}
	]
	
	for test in test_pieces:
		var piece = piece_scene.instantiate()
		add_child(piece)
		piece.set_values(test.values[0], test.values[1], 0.07)
		piece.position = test.pos
		piece.global_rotation = 0
		piece.global_scale = Vector2(1, 1)
		piece.load_piece()
