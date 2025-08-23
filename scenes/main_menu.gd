extends Control

@onready var menu: Window = $Menu

func _ready():
	menu.play_button_pressed.connect(_on_play_pressed)

func _on_toggle_change(button_pressed: bool):		#Activa o Desactiva el jugador humano
	Global.playing = !button_pressed

func _on_play_pressed():		#Inicia el juego
	get_tree().change_scene_to_file("res://scenes/game.tscn")
