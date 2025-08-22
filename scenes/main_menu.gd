extends Control

func _ready():
	show_game_start_message()
	

func show_game_start_message():
	
	var menu = preload("res://scenes/menu.tscn").instantiate()
	var toggle = CheckBox.new()
	
	toggle.text = "Solo IAs"
	
	toggle.toggled.connect(_on_toggle_change)
	
	
	#menu.confirmed.connect(_on_play_pressed)

func _on_toggle_change(button_pressed: bool):
	pass
	#playing = !button_pressed
