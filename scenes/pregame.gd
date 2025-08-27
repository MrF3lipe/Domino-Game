extends Window

signal play_pressed
signal active_dev

func _on_play_pressed():
	if Global.modified:
		active_dev.emit()
	play_pressed.emit()
	self.hide()

func _on_check_button_toggled(toggled_on: bool) -> void:
	Global.modified = toggled_on


func _on_check_button_2_toggled(toggled_on: bool) -> void:
	Global.playing = !toggled_on
	
	if toggled_on:
		$CheckButton3.button_pressed = false
		Global.players = false


func _on_check_button_3_toggled(toggled_on: bool) -> void:
	Global.players = toggled_on
	
	if toggled_on:
		$CheckButton2.button_pressed = false
		Global.playing = true
