tool
extends Button

const SCN_SettingsPopup: PackedScene = preload("res://addons/posepal/settings_popup/SettingsPopup.tscn")

func _ready() -> void:
	connect("pressed", self, "_on_pressed")
	icon = owner.pluginInstance.editorControl.get_icon("GDScript", "EditorIcons")

func _on_pressed():
	var settingsPopup: Popup = SCN_SettingsPopup.instance()
	add_child(settingsPopup)



