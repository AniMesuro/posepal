tool
extends VBoxContainer

const SCN_PropertyDisplay: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyDisplay.tscn")
#const SCN_NodeItem: PackedScene = preload("res://addons/posepal/batch_key_popup/NodeItem.tscn")
const SCN_PropertyItem: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyItem.tscn")

export var title: String = 'Node'

var unselectedPropertyData: Dictionary = {}

func fill_properties():
	return
	SCN_PropertyItem.instance()

func insert_propertyDisplay(nodeItem: Control, child_id: int):
	var propertyDisplay: Control = SCN_PropertyDisplay.instance()
#	propertyDisplay.nodeItem = nodeItem
	var batchAddVBox: VBoxContainer = $"../../../BatchAddVBox"
	var batchAddLineEdit: LineEdit = $"../../../BatchAddVBox/HBox/LineEdit"
	var editedSceneRoot = get_tree().edited_scene_root
	var poseSceneRoot = editedSceneRoot.get_node_or_null(owner.posepalDock.poselib_scene)
	
	var node = nodeItem.node
	propertyDisplay.node = node
	propertyDisplay.title = node.name
	propertyDisplay.display_id = child_id
	propertyDisplay.node_nodepath = poseSceneRoot.get_path_to(node)
	
		# Find adequate child_id
	var prev_child: Node = null
	var first: bool = false
	
	for i in get_child_count():
		var ch: Node = get_child(i)
		if propertyDisplay.display_id < ch.display_id:
			if i >0: prev_child = get_child(i-1); else: first = true
			print(node.name,' ',i)
			break
	if is_instance_valid(prev_child):
		add_child_below_node(prev_child, propertyDisplay)#new_child_id)
	else:
		add_child(propertyDisplay)
		if first: move_child(propertyDisplay, 0)
	
	if propertyDisplay.node_nodepath in unselectedPropertyData.keys():
		print("Propertyies = ",unselectedPropertyData[propertyDisplay.node_nodepath])
		for property in unselectedPropertyData[propertyDisplay.node_nodepath]:
			propertyDisplay.add_propertyItem(property)
		unselectedPropertyData.erase(propertyDisplay.node_nodepath)
	
	var node_valid: bool = propertyDisplay.validate_batch_property(batchAddLineEdit.text)
	if (batchAddVBox.valid_state == batchAddVBox.ValidState.INVALID) && node_valid:
		batchAddVBox.valid_state = batchAddVBox.ValidState.PARTIAL
	elif (batchAddVBox.valid_state == batchAddVBox.ValidState.VALID) && !node_valid:
		batchAddVBox.valid_state = batchAddVBox.ValidState.PARTIAL
#	sort_children()

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
	print('remove ',node)
	for ch in get_children():
		if ch.node == node:
#			var editedSceneRoot = get_tree().edited_scene_root
#			var poseSceneRoot = editedSceneRoot.get_node_or_null(owner.posepalDock.poselib_scene)
			unselectedPropertyData[ch.node_nodepath] = []
			var all_properties: PoolStringArray = ch.get_properties()
			unselectedPropertyData[ch.node_nodepath].resize(all_properties.size())
#			print("full unsel ",unselectedPropertyData)
			for i in all_properties.size():
				var property: String = all_properties[i]
#				print('89 property ',property)
#				unselectedPropertyData[ch.node_nodepath].push_back(property)
				unselectedPropertyData[ch.node_nodepath][i] = property
#				print(unselectedPropertyData[ch.node_nodepath].size())
			ch.queue_free()
			print("full unsel ",unselectedPropertyData)
			return
