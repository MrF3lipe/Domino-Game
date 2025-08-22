extends Window

signal play_button_pressed

func _on_play_button_pressed():
	play_button_pressed.emit()
	self.hide()

func _on_options_button_pressed():
	var menu = load("res://scenes/options.tscn").instantiate()
	get_tree().current_scene.add_child(menu)

func _on_quit_button_pressed():
	get_tree().quit()
