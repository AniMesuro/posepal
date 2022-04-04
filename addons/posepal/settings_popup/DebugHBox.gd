tool
extends "res://addons/posepal/settings_popup/SettingsOptionHBox.gd"

func _ready() -> void:
	if !is_instance_valid(owner.pluginInstance):
		return
	if get_tree().edited_scene_root == owner:
		return
	var settings: Resource = owner.pluginInstance.settings
	var popupMenu: PopupMenu = $MenuButton.get_popup()
	
	popupMenu.clear()
	for bool_option in settings.BoolToggle:
		popupMenu.add_item(bool_option)
#	$MenuButton.connect("pressed", self, "_on_pressed")
	popupMenu.connect("id_pressed", self, "_on_id_pressed")
