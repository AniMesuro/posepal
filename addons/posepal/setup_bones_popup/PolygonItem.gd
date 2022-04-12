tool
extends HBoxContainer

signal checked_node (nodeItem, child_id, value)
signal bone_selected (node_path, bone_path)

const SCN_BonePopup: PackedScene = preload("res://addons/posepal/setup_bones_popup/BonePopup.tscn")

export var node_type :String= "Node" setget _set_node_type
export var node_name :String= "Node" setget _set_node_name
export var nesting_level: int = 0 setget _set_nesting_level
export var child_id: int = -1
export var is_expanded: bool = true setget  _set_is_expanded
export var is_boned: bool = false setget _set_is_boned
export var is_polygon2d: bool = true setget _set_is_polygon2d
var node_path: NodePath
var bone_path: NodePath setget _set_bone_path

var node: Node
var parentItem: Node
var childrenItems: Array = [] setget _set_childrenItems

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorInterface: EditorInterface
var editorControl: Control

var expandButton: TextureButton

func _enter_tree() -> void:
	if !Engine.editor_hint:
		return
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	editorInterface = pluginInstance.get_editor_interface()
	editorControl = editorInterface.get_base_control()
	
#	expandButton = $"ExpandButton"
#	expandButton.visible = false

func _ready() -> void:
	expandButton = $"ExpandButton"
	expandButton.connect("pressed", self, "_on_ExpandButton_pressed")
	if !Engine.editor_hint:
		return
	self.childrenItems = childrenItems
	self.is_expanded = is_expanded
	self.is_boned = is_boned
	
	owner = get_parent().owner
	var boneButton: Button = $BoneButton
	var boneIcon: TextureRect = $BoneIcon
	boneIcon.texture = editorControl.get_icon("Bone", "EditorIcons")
	boneButton.connect("pressed", self, "_on_BoneButton_pressed")
#	var icon: TextureRect = $Icon
#	icon.texture = 

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
	self.is_polygon2d = (node_type == 'Polygon2D')

func _set_node_name(new_node_name :String):
	node_name = new_node_name
	$Label.text = new_node_name

func _set_is_expanded(new_is_expanded: bool):
	is_expanded = new_is_expanded
	if !is_inside_tree(): return
	
	expandButton = $"ExpandButton"
	if childrenItems.size() > 0 && Engine.editor_hint:
		pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
		editorInterface = pluginInstance.get_editor_interface()
		editorControl = editorInterface.get_base_control()
#		expandButton.visible = true
		if !new_is_expanded:
			expandButton.texture_normal = editorControl.get_icon("GuiTreeArrowDown", "EditorIcons")
		else:
			expandButton.texture_normal = editorControl.get_icon("GuiTreeArrowRight", "EditorIcons")
#	else:
#		expandButton.visible = false
	set_visible_childrenItems(new_is_expanded)

func _set_is_boned(new_is_boned: bool):
#	print('boned',new_is_boned)
	if !is_inside_tree():
		return
	if !is_polygon2d:
		return
	is_boned = new_is_boned
	editorInterface = pluginInstance.get_editor_interface()
	editorControl = editorInterface.get_base_control()
	
	var boneIcon: TextureRect = $BoneIcon
	var boneButton: Button = $BoneButton
	if !is_boned:
		boneIcon.modulate = Color(.4,.4,.7)
		boneButton.text = '--'
#		boneIcon.texture = editorControl.get_icon("Bone2D", "EditorIcons")
	else:
		boneIcon.modulate = Color.white
#		boneIcon.texture = editorControl.get_icon("Bone", "EditorIcons")

func _set_is_polygon2d(new_is_polygon2d: bool):
	is_polygon2d = new_is_polygon2d
	if !is_inside_tree():
		return
	$VSeparator.visible = is_polygon2d
	$BoneButton.visible = is_polygon2d
	$BoneIcon.visible = is_polygon2d
	if !is_polygon2d:
		$Label.add_color_override("font_color", Color(.5, .5, .5))
	else:
		$Label.add_color_override("font_color", Color.white)

func set_visible_childrenItems(new_visible: bool, parent_expanded: bool = true):
	for item in childrenItems:
		item.visible = new_visible
		if new_visible && !item.is_expanded:
			continue
			
		item.set_visible_childrenItems(new_visible)

func _on_ExpandButton_pressed():
	self.is_expanded = !is_expanded
#	print(childrenItems)

#func _on_CheckButton_pressed():
#	var checkButton = $CheckButton
#	emit_signal("checked_node", self, child_id, checkButton.pressed)
#	emit_signal("checked_node", node, child_id, checkButton.pressed)

func _on_BoneButton_pressed():
	var bonePopup = SCN_BonePopup.instance()
	bonePopup.posepalDock = get_parent().owner.posepalDock
	bonePopup.skeletonRoot = get_parent().poseSkeleton
	add_child(bonePopup)
	var boneButton: Button = $BoneButton
	var popup_pos = Vector2(boneButton.rect_global_position.x + boneButton.rect_size.x, boneButton.rect_global_position.y)
	bonePopup.popup(Rect2(popup_pos, Vector2(400,400)))
	bonePopup.connect("bone_selected", self, "_on_bonePopup_bone_selected")

func _set_childrenItems(new_childrenItems: Array):
	childrenItems = new_childrenItems
#	print(childrenItems)
	if !is_inside_tree():
		return
	expandButton = $"ExpandButton"

	if new_childrenItems.size() == 0:
		expandButton.texture_normal = null
#		print('aa')
#		expandButton.rect_size.y = 0
	else:
		self.is_expanded = true
#		expandButton.rect_size.y = 24

func _on_bonePopup_bone_selected(_bone_path: NodePath):
#	print('bone path ',_bone_path)
	self.bone_path = _bone_path
	owner.update_bone_relationship(node_path, bone_path)


func _get_pluginInstance():
	if is_instance_valid(pluginInstance):
		return pluginInstance
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _set_bone_path(new_bone_path: NodePath):
	if !is_instance_valid(get_parent().poseSkeleton) or !is_instance_valid(get_parent().poseSkeleton.get_node(new_bone_path)):
		self.is_boned = false
		return
	bone_path = new_bone_path
	$BoneButton.text = str(bone_path).split('/')[-1]
	$BoneButton.hint_tooltip = bone_path
	self.is_boned = true
