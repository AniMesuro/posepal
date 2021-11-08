tool
extends VBoxContainer

const SCN_NodeOption :PackedScene= preload("res://addons/posepal/new_pose_popup/NodeOption.tscn")

var selected_nodepaths :PoolStringArray= PoolStringArray([])

var pluginInstance :EditorPlugin

func _ready() -> void:
	pluginInstance = get_tree().get_nodes_in_group("plugin pose_library")[0]

func fill_nodes():
	clear_nodes()
	print('self ',is_instance_valid(self))
	
	var editedSceneRoot = get_tree().edited_scene_root
	var poseSceneRoot :Node= editedSceneRoot.get_node(owner.poselib_scene)
	
	var poseSceneTree :Array= get_relevant_children()
	
	for i in poseSceneTree.size():
		var node :Node= poseSceneTree[i]
		
		var nodeOption :HBoxContainer= SCN_NodeOption.instance()
		add_child(nodeOption)
		nodeOption.node_name = node.name
		nodeOption.node_type = node.get_class()
		nodeOption.connect("changed_selection", self, "_on_nodeOption_changed_selection")
		
		var path :String= poseSceneRoot.get_path_to(node)
		nodeOption.node_nodepath = path
#		print("path =",path)
		if path != ".":
			nodeOption.nesting_layer = path.count("/") + 1
		else:
			nodeOption.nesting_layer = 0

func clear_nodes():
	selected_nodepaths = []
	for nodeOption in get_children():
		nodeOption.queue_free()

func _on_nodeOption_changed_selection(nodeOption :HBoxContainer):
	if !nodeOption.is_selected:
#		Remove nodepath from selection array
		for i in selected_nodepaths.size():
			var nodepath = selected_nodepaths[i]
			if nodepath == nodeOption.node_nodepath:
				selected_nodepaths.remove(i)
				break
	else:
		if !nodeOption.node_nodepath in selected_nodepaths:
			selected_nodepaths.append(nodeOption.node_nodepath)
#	print("nodeoption :",nodeOption.node_nodepath,' ',nodeOption.is_selected)
	print(selected_nodepaths)

func get_relevant_children() -> Array:
	if !is_inside_tree():
		print('treedisplay outside tree')
		return []
	var editedSceneRoot = get_tree().edited_scene_root
	var poseSceneRoot :Node= editedSceneRoot.get_node_or_null(owner.poselib_scene)
	if !is_instance_valid(poseSceneRoot):
		print('posesceneroot not valid')
		return []
	
	var poseSceneTree :Array= [poseSceneRoot]
	
	#For each child and its 5 children layers, reference itself to the poseSceneTree Array
	for child in poseSceneRoot.get_children():
		poseSceneTree.append(child)
		
		for child_a in child.get_children():
			poseSceneTree.append(child_a)
			
			for child_b in child_a.get_children():
				poseSceneTree.append(child_b)
				
				for child_c in child_b.get_children():
					poseSceneTree.append(child_c)
					
					for child_d in child_c.get_children():
						poseSceneTree.append(child_d)
						
						for child_e in child_d.get_children():
							poseSceneTree.append(child_e)
	return poseSceneTree
