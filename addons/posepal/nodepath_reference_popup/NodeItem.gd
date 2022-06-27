tool
extends HBoxContainer

export var child_id: int
export var node_path: NodePath
export var node_type: String= "Node" setget _set_node_type
export var node_name: String= "Node" setget _set_node_name
export var nesting_level: int = 0 setget _set_nesting_level
export var is_expanded: bool = true setget _set_is_expanded
export var is_disabled: bool = false setget _set_is_disabled

const TEX_Expand: StreamTexture = preload("res://addons/posepal/assets/icons/icon_expand.png")
const TEX_ExpandCollapse: StreamTexture = preload("res://addons/posepal/assets/icons/icon_expand_collapsed.png")

#var node_path: NodePath
var childrenItems: Array = []
var parentItem: Node
var node: Node

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorInterface: EditorInterface
var editorControl: Control

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	owner = get_parent().owner
#	print('node ',node,' skel ',owner.skeletonRoot)
#	bone_path = owner.skeletonRoot.get_path_to(node)
	$Button.connect("pressed", owner, "_on_NodeButton_pressed", [node_path])
	$ExpandButton.connect("pressed", self, "_on_ExpandButton_pressed")

func _set_nesting_level(new_nesting_level: int):
	if !is_inside_tree():
		return
	if new_nesting_level < 0: return
	var separatorHBox: HBoxContainer = $"SeparatorHBox"
	
	
	
	
	var separators_to_instance: int = new_nesting_level - separatorHBox.get_child_count()
	if separators_to_instance > 0:
		for i in separators_to_instance:
			separatorHBox.add_child(VSeparator.new())
	else:
		for i in abs(separators_to_instance):
			separatorHBox.get_child(0).queue_free()
	
	nesting_level = new_nesting_level

func _set_node_type(new_node_type :String):
	if !is_inside_tree(): return
#	if is_instance_valid(self): return
	if !Engine.editor_hint: return
	
	if !is_instance_valid(self.pluginInstance.editorControl):
		pluginInstance.editorControl = pluginInstance.get_editor_interface().get_base_control()
	
	var icon: TextureRect = $Icon
	if type_exists(new_node_type):
		icon.texture = self.pluginInstance.editorControl.get_icon(new_node_type, "EditorIcons")
	else:
		icon.texture = self.pluginInstance.editorControl.get_icon("Node","EditorIcons")
	
	node_type = new_node_type
	if node_type == 'Bone2D':
		self.is_disabled = false
	else:
		self.is_disabled = true

func _set_node_name(new_node_name :String):
	node_name = new_node_name
	if is_inside_tree():
		return
	$Button.text = new_node_name

func _set_is_disabled(new_is_disabled: bool):
	is_disabled = new_is_disabled
	if !is_inside_tree():
		return
#	$VSeparator.visible = is_disabled
#	$BoneButton.visible = is_disabled
#	$BoneIcon.visible = is_disabled
	$Button.disabled = is_disabled
#	if !is_disabled:
#		$Label.add_color_override("font_color", Color(.5, .5, .5))
#	else:
#		$Label.add_color_override("font_color", Color.white)

func _set_is_expanded(new_is_expanded: bool):
	is_expanded = new_is_expanded
	
	
	if is_expanded:
		$ExpandButton.texture_normal = TEX_Expand
	else:
		$ExpandButton.texture_normal = TEX_ExpandCollapse
	update_childrenItems_visibility(is_expanded)

func update_childrenItems_visibility(new_visibility: bool):
	for ch in childrenItems:
		ch.visible = new_visibility
		ch.update_childrenItems_visibility(new_visibility)

func _get_pluginInstance():
	if is_instance_valid(pluginInstance):
		return pluginInstance
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _on_ExpandButton_pressed():
	self.is_expanded = !self.is_expanded
	
