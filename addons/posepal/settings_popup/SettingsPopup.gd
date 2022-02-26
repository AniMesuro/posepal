tool
extends WindowDialog

const RES_PosePalSettings: Script = preload("res://addons/posepal/PosePalSettings.gd")

var pluginInstance: EditorPlugin setget ,_get_pluginInstance

func _enter_tree() -> void:
	show()
	visible = true

func load_settings():
	var settings: RES_PosePalSettings = self.pluginInstance.settings
	var extensionMenu: MenuButton = $"MarginCon/VBox/ExtensionHBox/MenuButton"
	var extensionPopup: PopupMenu = extensionMenu.get_popup()
	extensionMenu.text = extensionPopup.get_item_text(settings.poselib_extension)
	
#	print(extensionMenu.items)#select(settings.poselib_extension)

func _ready() -> void:
	var saveButton: Button = $"MarginCon/VBox/SaveButton"
	saveButton.connect("pressed", self, "_on_saveButton_pressed")
	
	_setup_options()
	load_settings()
	
func _setup_options():
	var extensionMenu: MenuButton = $"MarginCon/VBox/ExtensionHBox/MenuButton"
	var popupMenu: PopupMenu = extensionMenu.get_popup()
	

func _get_pluginInstance() -> EditorPlugin:
	if is_instance_valid(pluginInstance):
		return pluginInstance
	if get_tree().get_nodes_in_group("plugin posepal").size() == 0:
		queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _on_saveButton_pressed():
	var settings: RES_PosePalSettings = self.pluginInstance.settings
	settings.poselib_extension = $"MarginCon/VBox/ExtensionHBox".selected_id
	queue_free()
