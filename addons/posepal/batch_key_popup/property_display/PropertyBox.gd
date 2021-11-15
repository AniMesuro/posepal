tool
extends VBoxContainer

const SCN_PropertyDisplay: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyDisplay.tscn")
#const SCN_NodeItem: PackedScene = preload("res://addons/posepal/batch_key_popup/NodeItem.tscn")
const SCN_PropertyItem: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyItem.tscn")

export var title: String = 'Node'

func fill_properties():
	return
	SCN_PropertyItem.instance()

func insert_propertyDisplay(nodeItem: Control, child_id: int):
	var propertyDisplay: Control = SCN_PropertyDisplay.instance()
#	propertyDisplay.nodeItem = nodeItem
	
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
	for ch in get_children():
		if ch.node == node:
			ch.queue_free()
			return
