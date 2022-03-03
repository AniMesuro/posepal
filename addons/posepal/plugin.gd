tool
extends EditorPlugin

# Animation Pose Library
# By AniMesuro

const plugin_group: String = "plugin posepal"

const SCN_PosePalDock: PackedScene = preload("res://addons/posepal/dock/PosePalDock.tscn")


# Editor References
var animationPlayerEditor :Node
var animationPlayerEditor_CurrentTime_LineEdit :LineEdit
var animationPlayerEditor_CurrentAnimation_OptionButton :OptionButton

#var animationTimelineEdit: Node
#var animationTrackEditor: Node
#var animationTrackScrollContainerVBox: VBoxContainer
#var customTrack: Control
#var customQueueKeyMarker: TextureRect

var editorSceneTabs: Tabs setget ,_get_EditorSceneTabs

var settings: Resource setget ,_get_settings
var posePalDock :Control
var editorControl :Control

func _enter_tree() -> void:
	add_to_group(plugin_group)
	
	self.editorSceneTabs.visible = true
#	yield(get_tree(), "idle_frame")

func _ready() -> void:
	posePalDock = SCN_PosePalDock.instance()
	posePalDock.pluginInstance = self
	editorControl = get_editor_interface().get_base_control()
	posePalDock.editorControl = editorControl
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, posePalDock)
	_get_editor_references()
	
	settings = load("res://addons/posepal/settings.tres")

func _get_settings():
	if !is_instance_valid(settings):
		settings = load("res://addons/posepal/settings.tres")
	
	return settings

func _exit_tree() -> void:
	self.editorSceneTabs.visible = true
	
	# Get AnimationTrack's custom queue_key marker.
#	if !is_instance_valid(animationPlayerEditor):
#		for node in get_tree().get_nodes_in_group('_vp_unhandled_key_input1235'):
#			if node.get_class() == 'AnimationPlayerEditor':
#				animationPlayerEditor = node
#				break
#		for child in animationPlayerEditor.get_children():
#			if child.get_class() == 'AnimationTrackEditor':
#				animationTrackEditor = child
#				break
#		animationTimelineEdit = animationTrackEditor.get_child(0
#	).get_child(0).get_child(0).get_child(0)
#	if animationTimelineEdit.get_child(0).has_node('CustomQueueKeyMarker'):
#		animationTimelineEdit.get_child(0).get_node('CustomQueueKeyMarker').queue_free()
	
	
	if !is_instance_valid(posePalDock):
		return
	remove_control_from_docks(posePalDock)
	


func _get_editor_references():
	if !is_inside_tree():
		print('not in tree')
	if !is_instance_valid(self):
		print('plugin not valid')
	
#	used to reference AnimationPlayerEditor from group '_vp_unhandled_key_input1235',
#	but it always changes for each Godot version.
	animationPlayerEditor = _select_from_child_ids(_get_editorVBox(), [1, 1, 1, 0, 0, 1, 0, 1])
	if !is_instance_valid(animationPlayerEditor):
		print("[posepal] Couldn't get Editor's AnimationPlayerEditor reference")
		return
	
	# Get HBoxContainer
	var _hBox :HBoxContainer
	var _children: Array = animationPlayerEditor.get_children()
	for child in _children:
		if child.get_class() == 'HBoxContainer':
			_hBox = child
			break
#	for child in _children:
#		if child.get_class() == 'AnimationTrackEditor':
#			animationTrackEditor = child
#			print('trackedit ',animationTimelineEdit)
#			break
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
#			print('vbox ',child)
			return child
