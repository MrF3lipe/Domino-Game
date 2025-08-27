extends Window

@onready var options: Window = $Options

signal play_button_pressed

# Va al menu Jugar
func _on_play_button_pressed():
	play_button_pressed.emit()
	self.hide()

# Va al menu opciones
func _on_options_button_pressed():
	var menu = load("res://scenes/options.tscn").instantiate()
	get_tree().current_scene.add_child(menu)
	self.hide()

# Sale del juego
func _on_quit_button_pressed():
	get_tree().quit()
