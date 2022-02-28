tool
extends HBoxContainer


const SCN_FileSelectorPreview: PackedScene = preload("res://addons/posepal/file_selector_preview/FileSelectorPreview.tscn")
var fileSelectorPreview: Control

func _ready() -> void:
	$OpenButton.connect("pressed", self, "_on_OpenButton_pressed")
	



func _on_OpenButton_pressed():
	fileSelectorPreview = SCN_FileSelectorPreview.instance()
	$OpenButton.add_child(fileSelectorPreview)
