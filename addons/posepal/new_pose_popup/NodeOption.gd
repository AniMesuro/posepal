#tool
extends HBoxContainer

signal changed_selection (nodeOption)

export var node_type :String= "Node" setget _set_node_type
export var node_name :String= "Node" setget _set_node_name
export var nesting_layer :int= 0 setget _set_nesting_layer # How many layers of nessting from the scene root.
var node_nodepath :String
var is_selected :bool= false setget _set_is_selected

func _ready() -> void:
	$CheckBox.connect("toggled", self, "_on_CheckBox_toggled")

func _on_CheckBox_toggled(button_pressed :bool):
	self.is_selected = button_pressed

func _set_is_selected(value :bool):
	if is_selected == value:
		return
	is_selected = value
	emit_signal("changed_selection", self)

func _set_node_type(new_node_type :String):
	if !is_inside_tree():
		yield(self, "tree_entered")
	if get_tree().edited_scene_root == self:
		return
	
	var pluginInstance :EditorPlugin= get_parent().pluginInstance
#	print(name,' pluginInstance ',pluginInstance)
	pluginInstance.editorControl = pluginInstance.get_editor_interface().get_base_control()
#	if !is_instance_valid(pluginInstance.editorControl): print('editor control invalid')
	var icon :TextureRect= $Icon
	
	if type_exists(new_node_type):
		icon.texture = pluginInstance.editorControl.get_icon(new_node_type, "EditorIcons")
	else:
		icon.texture = pluginInstance.editorControl.get_icon("Node","EditorIcons")
	
	node_type = new_node_type
	# Set Icon

func _set_node_name(new_node_name :String):
	if !is_inside_tree():
		yield(self, "tree_entered")
	
	node_name = new_node_name
	$Label.text = new_node_name

func _set_nesting_layer(new_nesting_layer :int):
	if !is_inside_tree():
		return
	if new_nesting_layer < 0:
		return
	var nestingLabel :Label = $NestingLabel
	
	
	nesting_layer = new_nesting_layer
	
	nestingLabel.text = ""
	for i in nesting_layer:
		nestingLabel.text = nestingLabel.text + "|"

