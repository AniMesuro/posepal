tool
extends WindowDialog

onready var RES_PosePalSettings: GDScript = load("res://addons/posepal/PosePalSettings.gd")

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var posepalDock: Control

func _enter_tree() -> void:
	show()
	visible = true

func load_settings():
	var settings: Resource = self.pluginInstance.settings
	var extensionMenu: MenuButton = $"MarginCon/VBox/ExtensionHBox/MenuButton"
	var extensionPopup: PopupMenu = extensionMenu.get_popup()
	extensionMenu.text = extensionPopup.get_item_text(settings.poselib_extension)

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	if !is_instance_valid(posepalDock):
		return
	var saveButton: Button = $"MarginCon/VBox/SaveButton"
	saveButton.connect("pressed", self, "_on_saveButton_pressed")
	load_settings()

func _get_pluginInstance() -> EditorPlugin:
	if is_instance_valid(pluginInstance):
		return pluginInstance
	if get_tree().get_nodes_in_group("plugin posepal").size() == 0:
		# queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _on_saveButton_pressed():
	var settings: Resource = self.pluginInstance.settings
	settings.poselib_extension = $"MarginCon/VBox/ExtensionHBox".selected_id
	var selectedScene: Node= get_tree().edited_scene_root.get_node_or_null(posepalDock.poselib_scene)
	posepalDock.save_poseData()
	
	queue_free()
