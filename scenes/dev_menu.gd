extends Window

signal dev_add(l, r, p)

@onready var text: TextEdit = $TextEdit

func _on_button_pressed():
	var l = int(text.text[0])
	var r = int(text.text[2])
	var p = int(text.text[4])
	dev_add.emit(l,r,p)
