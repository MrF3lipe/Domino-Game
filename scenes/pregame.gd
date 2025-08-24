extends Window

signal play_pressed

func _on_play_pressed():
	play_pressed.emit()
	self.hide()

func _on_ia_toggled_toggled(toggled_on):
	Global.playing = !toggled_on
