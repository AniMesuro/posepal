tool
extends HBoxContainer

export var _expandableControl :NodePath
var is_expanded: bool = true setget _set_is_expanded

func _ready() -> void:
	$"ExpandButton".connect("pressed", self, "_on_ExpandButton_pressed")
	$"AddPropertyButton".connect("pressed", self, "_on_AddPropertyButton_pressed")

func _on_ExpandButton_pressed():
	self.is_expanded = !is_expanded

func _set_is_expanded(new_is_expanded: bool):
	is_expanded = new_is_expanded
	var expandableControl = get_node(_expandableControl)
	expandableControl.visible = is_expanded
	

func _on_AddPropertyButton_pressed():
	var addHBox: HBoxContainer = $"../AddHBox"
	addHBox.visible = !addHBox.visible

