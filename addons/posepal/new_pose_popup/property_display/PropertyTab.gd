tool
extends VBoxContainer

export var expand :bool= false setget _set_expand
export var node_nodepath :String= "Node" setget _set_node_nodepath
export var node_type :String= "Node" setget _set_node_type
var pose :Dictionary setget _set_pose,_get_pose
var node: Node

var nodeRef :Node

var tabLabel :Label
var tabIcon :TextureRect

#func _ready() -> void:
#	$NodePropertyTab/TabHBox/ExpandButton.connect("pressed", self, "_on_ExpandButton_pressed")

func _set_expand(new_expand :bool):
	if !is_inside_tree():
		return
#		yield(self, "tree_entered")
	if expand == new_expand:
		return
	
	$ExpandVBox.visible = new_expand
	
	expand = new_expand

func _set_node_type(new_node_type :String):
	if !is_inside_tree():
		return
#		yield(self, "tree_entered")
	if get_tree().edited_scene_root == self:
		return
		
	var pluginInstance :EditorPlugin= get_parent().pluginInstance
	if !is_instance_valid(pluginInstance): return
	pluginInstance.editorControl = pluginInstance.get_editor_interface().get_base_control()
	tabIcon = $"NodePropertyTab/TabHBox/Icon"
	
	if type_exists(new_node_type):
		tabIcon.texture = pluginInstance.editorControl.get_icon(new_node_type, "EditorIcons")
	else:
		tabIcon.texture = pluginInstance.editorControl.get_icon("Node","EditorIcons")
	
	node_type = new_node_type

func _set_node_nodepath(new_node_nodepath):
	if !is_inside_tree():
		return
#		yield(self, "tree_entered")
	var editedSceneRoot :Node= get_tree().edited_scene_root
	if editedSceneRoot == self:
		return
	var poseSceneRoot :Node= get_parent().poseSceneRoot#editedSceneRoot.get_node(get_parent().poseSceneRoot)
		
	tabLabel = $"NodePropertyTab/TabHBox/NodePathLabel"
	if new_node_nodepath != ".":
#		print('parent ',get_parent())
		nodeRef = poseSceneRoot.get_node(new_node_nodepath)
		tabLabel.text = new_node_nodepath
		hint_tooltip = new_node_nodepath
	else:
#		poseSceneRoot = get_parent().poseSceneRoot#editedSceneRoot.get_node(get_parent().poseSceneRoot)
		nodeRef = poseSceneRoot
		tabLabel.text = "./"+poseSceneRoot.name
		hint_tooltip = "./"+poseSceneRoot.name
	
	if !self.pose.has(new_node_nodepath):
		self.pose[new_node_nodepath] = {}
	node_nodepath = new_node_nodepath

func _set_pose(new_pose :Dictionary):
	if get_tree().edited_scene_root == self:
		return
	get_parent().pose = new_pose

func _get_pose() -> Dictionary:
	if get_tree().edited_scene_root == self:
		return {}
	return get_parent().pose

#func _on_ExpandButton_pressed():
#	expand = !expand
