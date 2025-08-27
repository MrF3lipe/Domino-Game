extends Window

signal dev_add(l, r, p)

@onready var text: TextEdit = $TextEdit

func _on_button_pressed():
	var left = int(text.text[0])
	var right = int(text.text[2])
	var player = int(text.text[4])
	dev_add.emit(left, right, player)
