tool
extends HBoxContainer

export var selected_id: int setget _set_selected_id

func _ready() -> void:
	var settings: Resource = owner.pluginInstance.settings
	
	var popupMenu: PopupMenu = $MenuButton.get_popup()
	for extension in settings.PoselibExtensions:
		popupMenu.add_item(extension)
	$MenuButton.connect("pressed", self, "_on_pressed")
	popupMenu.connect("id_pressed", self, "_on_id_pressed")
	print(settings.PoselibExtensions.keys()[settings.poselib_extension])

func _on_pressed():
	pass

func _on_id_pressed(id: int):
	self.selected_id = id


func _set_selected_id(new_selected_id):
	selected_id = new_selected_id
	$MenuButton.text = $MenuButton.get_popup().get_item_text(selected_id)
