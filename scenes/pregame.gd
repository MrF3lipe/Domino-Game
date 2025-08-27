extends Window

signal play_pressed
signal active_dev

func _on_play_pressed():
	if Global.modified:
		active_dev.emit()
	play_pressed.emit()
	self.hide()

func _on_check_box_toggled(toggled_on):
	Global.modified = toggled_on


func _on_check_box_2_toggled(toggled_on):
	Global.playing = !toggled_on
