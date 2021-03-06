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
	for extension in settings.PoselibExtensions:
		popupMenu.add_item(extension)
	
#	$MenuButton.connect("pressed", self, "_on_pressed")
	popupMenu.connect("id_pressed", self, "_on_id_pressed")

#func _on_pressed():
#	pass

#func _on_id_pressed(id: int):
#	self.selected_id = id

#func _set_selected_id(new_selected_id):
#	selected_id = new_selected_id
#	$MenuButton.text = $MenuButton.get_popup().get_item_text(selected_id)
