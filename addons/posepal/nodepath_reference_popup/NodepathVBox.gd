tool
extends VBoxContainer

const SCN_NodepathItem: PackedScene = preload("res://addons/posepal/nodepath_reference_popup/NodepathItem.tscn")
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var children_as_dict: Dictionary = {}
func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		return
	if get_tree().edited_scene_root == get_parent().owner:
		return
	fill_nodepaths()

func fill_nodepaths():
#	var old_paths = owner.old_paths
	var poselib: RES_PoseLibrary = owner.poselib
	
	var poseRoot: Node = get_tree().edited_scene_root.get_node(owner.posepalDock.poselib_scene)
	if !is_instance_valid(poseRoot):
		return
	for np_id in poselib.nodepathReferences.keys():
		# Check if nodepath is valid.
		var nodepath: String = poselib.get_nodepath_from_id(np_id)#resourceReferences[np_id]#[0]
		var node: Node = poseRoot.get_node_or_null(nodepath)
		if is_instance_valid(node):
			continue
		owner.unfixed_nodepaths_num += 1
		var item: PanelContainer = SCN_NodepathItem.instance()
		
		item.old_path = nodepath
		item.np_id = np_id
		item.pure_name = nodepath.split('/',false)[-1]
		item.poseRoot = poseRoot
		if item.pure_name == '.':
			item.pure_name = poseRoot.name
		children_as_dict[np_id] = item
		add_child(item)
		item.connect('fixed_path', self, '_on_item_fixed_path')

func _on_item_fixed_path(ch: int):
#	$"../../../GuessButton".disabled = false
#	for child in get_children():
#		if child.is_connected('fixed_path', self, '_on_item_fixed_path'):
#			child.disconnect('fixed_path', self, '_on_item_fixed_path')
#	var child: Node = get_child(ch)
	owner.unfixed_nodepaths_num -= 1


