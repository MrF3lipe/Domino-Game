extends Window

@onready var options: Window = $Options

signal play_button_pressed

func _on_play_button_pressed():#Va al menu Jugar
	play_button_pressed.emit()
	self.hide()

func _on_options_button_pressed():			#Va al menu opciones
	var menu = load("res://scenes/options.tscn").instantiate()
	get_tree().current_scene.add_child(menu)
	self.hide()

func _on_quit_button_pressed():			#Sale del juego
	get_tree().quit()
