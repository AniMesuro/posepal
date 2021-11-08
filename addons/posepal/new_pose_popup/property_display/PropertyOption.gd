tool
extends HBoxContainer

signal requesting_property_removal (property)

export var pose_property :String= "name" setget _set_pose_property

func _ready() -> void:
	$RemoveButton.connect("pressed", self, "_on_pressed")

func _set_pose_property(new_pose_property :String):
	if !is_inside_tree():
		return
	$Label.text = new_pose_property
	pose_property = new_pose_property

func _on_pressed():
	emit_signal("requesting_property_removal", pose_property)

