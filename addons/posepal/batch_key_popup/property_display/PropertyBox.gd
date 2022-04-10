tool
extends VBoxContainer

const SCN_PropertyDisplay: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyDisplay.tscn")
const SCN_PropertyItem: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyItem.tscn")

export var title: String = 'Node'

var unselectedPropertyData: Dictionary = {}


func _ready() -> void:
	var nodeVBox: VBoxContainer = $"../../TreeScroll/VBox"
	nodeVBox.connect("checked_node", self, "_on_NodeVBox_checked_node")

func fill_properties():
	return

func insert_propertyDisplay(node: Node, child_id: int):
	var propertyDisplay: Control = SCN_PropertyDisplay.instance()
	var batchAddVBox: VBoxContainer = $"../../../BatchAddVBox"
	var batchAddLineEdit: LineEdit = $"../../../BatchAddVBox/HBox/LineEdit"
	var editedSceneRoot = get_tree().edited_scene_root
	var poseSceneRoot = editedSceneRoot.get_node_or_null(owner.posepalDock.poselib_scene)
#	var node = nodeItem.node
	
	propertyDisplay.node = node
	propertyDisplay.title = node.name
	propertyDisplay.display_id = child_id
	propertyDisplay.node_nodepath = poseSceneRoot.get_path_to(node)
	
	var prev_child: Node = null
	var first: bool = false
	
	for i in get_child_count():
		var ch: Node = get_child(i)
		if propertyDisplay.display_id < ch.display_id:
			if i > 0: prev_child = get_child(i-1); else: first = true
			break
	
	if is_instance_valid(prev_child):
		add_child_below_node(prev_child, propertyDisplay)#new_child_id)
	else:
		add_child(propertyDisplay)
		if first: move_child(propertyDisplay, 0)
	
	if propertyDisplay.node_nodepath in unselectedPropertyData.keys():
		for property in unselectedPropertyData[propertyDisplay.node_nodepath]:
			propertyDisplay.add_propertyItem(property)
		unselectedPropertyData.erase(propertyDisplay.node_nodepath)
	
		var node_valid: bool = propertyDisplay.validate_batch_property(batchAddLineEdit.text)
		if (batchAddVBox.valid_state == batchAddVBox.ValidState.INVALID) && node_valid:
			batchAddVBox.valid_state = batchAddVBox.ValidState.PARTIAL
		elif (batchAddVBox.valid_state == batchAddVBox.ValidState.VALID) && !node_valid:
			batchAddVBox.valid_state = batchAddVBox.ValidState.PARTIAL

func sort_children():
	if get_children().size() == 0: return
	
	var unsorted_children: Array = get_children()
	var sorted_children: Array = []
	
	while unsorted_children.size() > 0:
		var min_uv: int = 9223372036854775807
		var min_ui: int = -1
		
		for i in unsorted_children.size():
			var uch: Node = unsorted_children[i]
			if uch.display_id < min_uv:
				min_uv = uch.display_id
				min_ui = i
		sorted_children.append(unsorted_children[min_ui])
		unsorted_children.remove(min_ui)
		
	for i in sorted_children.size():
		var sch: Control = sorted_children[i]
		move_child(sch, i)

func remove_propertyDisplay(node: Node):
	for ch in get_children():
		if ch.node == node:
			unselectedPropertyData[ch.node_nodepath] = []
			var all_properties: PoolStringArray = ch.get_properties()
			unselectedPropertyData[ch.node_nodepath].resize(all_properties.size())
			
			for i in all_properties.size():
				var property: String = all_properties[i]
				unselectedPropertyData[ch.node_nodepath][i] = property
			ch.queue_free()
			return

func _on_NodeVBox_checked_node(node: Node, child_id: int, value: bool):
	if value:
		insert_propertyDisplay(node, child_id)
	else:
		remove_propertyDisplay(node)
