tool
extends Popup

signal name_settled (new_name)

var new_name :String= ""

onready var titlebar :HBoxContainer= $Panel/VBox/Titlebar
onready var label :Label= $Panel/VBox/Label
var parent :Node
var lineEdit :LineEdit
var button :Button

func _ready() -> void:
	popup_centered(rect_min_size)
	button = $Panel/VBox/Button
	lineEdit = $Panel/VBox/LineEdit

	button.connect("pressed", self, '_on_Button_pressed')
	lineEdit.connect("text_entered", self, '_on_LineEdit_entered')
	
	lineEdit.grab_focus()
	
func _on_Button_pressed() -> void:
	lineEdit = $Panel/VBox/LineEdit
	
	new_name = lineEdit.text
	emit_signal("name_settled", new_name)
	queue_free()

func _on_LineEdit_entered(new_text :String) -> void:
	new_name = new_text
	emit_signal("name_settled", new_name)
	queue_free()
