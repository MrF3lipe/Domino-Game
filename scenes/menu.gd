extends Window

signal play_button_pressed
var Game

func _ready():
	Game = preload("res://scenes/game.tscn").instantiate()
	
func _on_play_button_pressed():
	Game.play_pressed()

func _on_options_button_pressed():
	var menu = load("res://scenes/options.tscn").instantiate()

func _on_quit_button_pressed():
	pass  #Funcion para quitar el juego
