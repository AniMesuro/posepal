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

var posePalDock :Control
var editorControl :Control

func _enter_tree() -> void:
	add_to_group(plugin_group)
	
	
#	yield(get_tree(), "idle_frame")

func _ready() -> void:
	posePalDock = SCN_PosePalDock.instance()
	posePalDock.pluginInstance = self
	editorControl = get_editor_interface().get_base_control()
	posePalDock.editorControl = editorControl
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, posePalDock)
	_get_editor_references()
	
	

func _exit_tree() -> void:
	if !is_instance_valid(posePalDock):
		return
	remove_control_from_docks(posePalDock)


func _get_editor_references():
	if !is_inside_tree():
		print('not in tree')
	if !is_instance_valid(self):
		print('plugin not valid')
	
#	var animpled: Node = instance_from_id(9861)
#	print(animpled, animpled.name, animpled.get_groups())
#	return
	# AnimationPlayerEditor
	# < 3.2 used _vp_unhandled_key_input1176.
#	var sceneTimer: SceneTreeTimer = get
	for node in get_tree().get_nodes_in_group('_vp_unhandled_key_input1235'):
#		print(get_tree().get_nodes_in_group('_vp_unhandled_key_input1235'))
		if node.get_class() == 'AnimationPlayerEditor':
			animationPlayerEditor = node
			print("[PosePal] Acquired Editor's AnimationPlayerEditor reference")
			break
	if !is_instance_valid(animationPlayerEditor):
		print("[PosePal] Couldn't get Editor's AnimationPlayerEditor reference")
		return
	
	# Get HBoxContainer
	var _hBox :HBoxContainer
	for child in animationPlayerEditor.get_children():
		if child.get_class() == 'HBoxContainer':
			_hBox = child
			break
	if !is_instance_valid(_hBox):
		print("[PosePal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer reference")
		return
	
	# Get SpinBox -- current_time
	var _spinBox :SpinBox
	for child in _hBox.get_children():
		if child.get_class() == 'SpinBox':
			_spinBox = child
			animationPlayerEditor_CurrentTime_LineEdit = _spinBox.get_line_edit()
			break
	if !is_instance_valid(_spinBox):
		print("[PosePal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer/SpinBox reference")
		return
	
	# Get OptionButton -- current_animation
	for child in _hBox.get_children():
		if child.get_class() == 'OptionButton':
			animationPlayerEditor_CurrentAnimation_OptionButton = child
			break
	if !is_instance_valid(animationPlayerEditor_CurrentAnimation_OptionButton):
		print("[PosePal] Couldn't get Editor's AnimationPlayerEditor/HBoxContainer/OptionButton reference")
		return

# As reading tscn is a bit expensive, there should be a temporary variable that
# returns poseFile is referenced in tscn and its path.
func tscn_has_poseFile(tscn_path :String):
	pass



