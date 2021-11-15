tool
extends HBoxContainer

var node: Node
export var property: String = "" setget _set_property

func _ready() -> void:
	$"EraseButton".connect("pressed", self, "_on_EraseButton_pressed")

func _set_property(new_property: String):
	$Label.text = new_property
	property = new_property

func _on_EraseButton_pressed():
	return
	queue_free()
	# tell propertydisplay that this property will not be keyed.

