tool
extends Button

const SCN_SettingsPopup: PackedScene = preload("res://addons/posepal/settings_popup/SettingsPopup.tscn")

func _ready() -> void:
	connect("pressed", self, "_on_pressed")

	if !is_instance_valid(owner.pluginInstance):
		return
	icon = owner.pluginInstance.editorControl.get_icon("GDScript", "EditorIcons")

func _on_pressed():
	var settingsPopup: Popup = SCN_SettingsPopup.instance()
	settingsPopup.posepalDock = owner
	add_child(settingsPopup)
