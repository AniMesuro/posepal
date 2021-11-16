tool
extends VBoxContainer



const SCN_NodeItem: PackedScene =  preload("res://addons/posepal/batch_key_popup/NodeItem.tscn")

var poseSceneRoot: Node

func _ready() -> void:
	fill_nodes()
#	var propertyDisplay = $"../../PropertyScroll/PropertyDisplay"
#	propertyDisplay.connect

func clear_tree():
	for child in get_children():
		child.queue_free()

func fill_nodes():
	clear_tree()
#func get_relevant_children() -> Array:
	if !is_inside_tree():
		print('treedisplay outside tree')
		return
	if get_tree().edited_scene_root == owner: return
	var editedSceneRoot = get_tree().edited_scene_root
	poseSceneRoot = editedSceneRoot.get_node_or_null(owner.posepalDock.poselib_scene)
	if !is_instance_valid(poseSceneRoot):
		print('posesceneroot not valid')
		return 
	var _poseSceneRoot: Control = add_node_item(null, poseSceneRoot)
	
	#For each child and its 5 children layers, reference itself to the poseSceneTree Array
	for child in poseSceneRoot.get_children():
		var _child = add_node_item(_poseSceneRoot, child)
		
		for child_a in child.get_children():
			var _child_a = add_node_item(_child, child_a)
			
			for child_b in child_a.get_children():
				var _child_b = add_node_item(_child_a, child_b)
				
				for child_c in child_b.get_children():
					var _child_c = add_node_item(_child_b, child_c)
					
					for child_d in child_c.get_children():
						var _child_d = add_node_item(_child_c, child_d)
						
						for child_e in child_d.get_children():
							var _child_e = add_node_item(_child_d, child_e)

func add_node_item(parentItem: Node, node: Node) -> Node:
	var nodeItem: HBoxContainer = SCN_NodeItem.instance()
	nodeItem.node_name = node.name
#	nodeItem.node_nodepath = poseSceneRoot.get_path_to(node)
	nodeItem.node = node
	nodeItem.parentItem = parentItem
	nodeItem.child_id = get_child_count()
	add_child(nodeItem)
	nodeItem.node_type = node.get_class()
	nodeItem.is_expanded = true
	nodeItem.connect("checked_node", self, "_on_checked_node")
	if is_instance_valid(parentItem):
		parentItem.childrenItems.resize(parentItem.childrenItems.size()+1)
		parentItem.childrenItems[-1] = nodeItem
		nodeItem.nesting_level = parentItem.nesting_level+1
	# Child position might be redundant if copied corrected from scene.
	return nodeItem

func _on_checked_node(nodeItem: Control, child_id: int , value: bool):
	var node = nodeItem.node
	print(node, value)
	var propertyBox: VBoxContainer = $"../../PropertyScroll/VBox"
	
	if value:
		propertyBox.insert_propertyDisplay(nodeItem, child_id)
	else:
		propertyBox.remove_propertyDisplay(node)
	
	


