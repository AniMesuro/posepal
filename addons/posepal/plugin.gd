tool
extends EditorPlugin

# ------------------
# 		posepal
# Plugin by AniMesuro.
# 
# repo: 	https://github.com/AniMesuro/posepal
# ------------------

const plugin_group: String = "plugin posepal"

const SCN_PosePalDock: PackedScene = preload("res://addons/posepal/dock/PosePalDock.tscn")

# Editor References
var animationPlayerEditor: Node
var animationPlayerEditor_CurrentTime_LineEdit: LineEdit
var animationPlayerEditor_CurrentAnimation_OptionButton: OptionButton
var editorSceneTabs: Tabs setget ,_get_EditorSceneTabs

var settings: Resource setget ,_get_settings
var plugin_version: PoolIntArray = []

var posePalDock: Control
var editorControl: Control

func _enter_tree() -> void:
	add_to_group(plugin_group)
	self.editorSceneTabs.visible = true

func _ready() -> void:
	posePalDock = SCN_PosePalDock.instance()
	posePalDock.pluginInstance = self
	editorControl = get_editor_interface().get_base_control()
	posePalDock.editorControl = editorControl
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, posePalDock)
	_get_editor_references()
	settings = load("res://addons/posepal/settings.tres")
	
	var configFile: ConfigFile = ConfigFile.new()
	var err: int = configFile.load("res://addons/posepal/plugin.cfg")
	if err != OK:
		return
	var keys: PoolStringArray = configFile.get_section_keys('plugin')
	plugin_version = Array(configFile.get_value('plugin', 'version').split('.', false))
	

func _get_settings():
	if !is_instance_valid(settings):
		settings = load("res://addons/posepal/settings.tres")
	return settings

func _exit_tree() -> void:
	self.editorSceneTabs.visible = true
	if !is_instance_valid(posePalDock):
		return
	remove_control_from_docks(posePalDock)

func _get_editor_references():
	if !is_inside_tree():
		print('not in tree')
	if !is_instance_valid(self):
		print('plugin not valid')
	
	animationPlayerEditor = _select_from_child_ids(_get_editorVBox(), [1, 1, 1, 0, 0, 1, 0, 1])
	if !is_instance_valid(animationPlayerEditor):
		print("[posepal] Couldn't get Editor's AnimationPlayerEditor reference")
		return
	
	var _hBox :HBoxContainer
	var _children: Array = animationPlayerEditor.get_children()
	for child in _children:
		if child.get_class() == 'HBoxContainer':
			_hBox = child
			break
	_children = []
	
	if !is_instance_valid(_hBox):
		print("[posepal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer reference")
		return
	
	# Get SpinBox -- current_time
	var _spinBox :SpinBox
	for child in _hBox.get_children():
		if child.get_class() == 'SpinBox':
			_spinBox = child
			animationPlayerEditor_CurrentTime_LineEdit = _spinBox.get_line_edit()
			break
	if !is_instance_valid(_spinBox):
		print("[posepal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer/SpinBox reference")
		return
	
	# Get OptionButton -- current_animation
	for child in _hBox.get_children():
		if child.get_class() == 'OptionButton':
			animationPlayerEditor_CurrentAnimation_OptionButton = child
			break
	if !is_instance_valid(animationPlayerEditor_CurrentAnimation_OptionButton):
		print("[posepal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer/OptionButton reference")
		return
	
	self.editorSceneTabs

# As reading tscn is a bit expensive, there should be a temporary variable that
# returns poseFile is referenced in tscn and its path.
func tscn_has_poseFile(tscn_path :String):
	pass

func _get_EditorSceneTabs():
	return _select_from_child_ids(_get_editorVBox(), [1, 1, 1, 0, 0, 0, 0, 0, 1])

func _select_from_child_ids(current_node: Node, child_ids: PoolIntArray):
	var last_child: Node = current_node
	while child_ids.size() != 0:
		last_child = last_child.get_child(child_ids[0])
		child_ids.remove(0)
		if child_ids.size() == 0:
			return last_child
	return null

func _get_editorVBox():
	var _editorControl: Control = get_editor_interface().get_base_control()
	for child in _editorControl.get_children():
		if child.get_class() == 'VBoxContainer':
			return child
