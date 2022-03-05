tool
extends Panel

var handlerTop :ReferenceRect
var handlerBottom :ReferenceRect
var handlerLeft :ReferenceRect
var handlerRight :ReferenceRect

var vbox_margin :Vector2= Vector2(10, 20)
func _ready() -> void:
	$VBox.set_deferred("rect_size", rect_size - ( vbox_margin * 2))
	$VBox.set_deferred("rect_position", rect_position + vbox_margin)
