extends Control

@onready var menu: Window = $Menu

func _ready():
	menu.play_button_pressed.connect(_on_play_pressed)

# Activa o desactiva el jugador humano
func _on_toggle_change(button_pressed: bool):
	Global.playing = !button_pressed

# Inicia el juego
func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
