tool
extends VBoxContainer

signal checked_node (node, child_id, value)

export var sceneNodeItem: PackedScene

#const SCN_PolygonItem: PackedScene =  preload("res://addons/posepal/setup_bones_popup/PolygonItem.tscn")

export var node_type: String = ''

var poseRoot: Node
var poseSkeleton: Skeleton2D

var posepalDock: Control
func _ready() -> void:
	if owner == get_tree().edited_scene_root:
		return
	
	posepalDock = owner.posepalDock
	fill_nodes(poseRoot)
	if node_type == 'Bone2D':
		return
	load_bone_relationships()
	owner.update_bone_relationship('_skeleton', poseRoot.get_path_to(poseSkeleton))

func clear_tree():
	for child in get_children():
		child.queue_free()

func load_bone_relationships():
	for child in get_children():
		var nodeItem: Node = child
		if nodeItem.node_type == 'Polygon2D':
			if 'boneRelationshipData' in owner:
				var str_path: String = nodeItem.node_path
				if owner.boneRelationshipData.has(str_path):
	#				print(owner.boneRelationshipData[str_path])
					nodeItem.bone_path = owner.boneRelationshipData[str_path]

func fill_nodes(_poseRoot: Node = null):
	clear_tree()
	if !is_inside_tree():
		return
	if get_tree().edited_scene_root == owner:
		return
		
	var editedSceneRoot = get_tree().edited_scene_root
	if !is_instance_valid(_poseRoot):
		poseRoot = editedSceneRoot.get_node_or_null(posepalDock.poselib_scene)
#	else:
#		poseRoot = _poseRoot
#	if !is_instance_valid(poseRoot):
#		return
	
	var is_disabled: bool = false
	if node_type != '':
		is_disabled = !poseRoot.is_class(node_type)
	var _poseRootItem: Control = add_node_item(null, poseRoot, is_disabled)
	_add_children_items(poseRoot, _poseRootItem, 400)


func add_node_item(parentItem: Node, node: Node, disabled: bool = false) -> Node:
	var nodeItem: Control = sceneNodeItem.instance() #SCN_PolygonItem.instance()
	nodeItem.node_name = node.name
	nodeItem.node = node
	nodeItem.parentItem = parentItem
	nodeItem.child_id = get_child_count()
	add_child(nodeItem)
	nodeItem.node_type = node.get_class()
	nodeItem.is_expanded = true
	
	
	nodeItem.node_path = poseRoot.get_path_to(node)
	
				
#	nodeItem.connect("checked_node", self, "_on_checked_node")
	if nodeItem.node_type == 'Skeleton2D':
		poseSkeleton = node
	if is_instance_valid(parentItem):
		parentItem.childrenItems.resize(parentItem.childrenItems.size()+1)
		parentItem.childrenItems[-1] = nodeItem
		nodeItem.nesting_level = parentItem.nesting_level+1
	return nodeItem

var _add_children_items_iter: int = 0
func _add_children_items(parent: Node, parentItem: Node, max_iter: int = 0):
	if max_iter >  0:
		_add_children_items_iter = max_iter
		
	for child in parent.get_children():
		if _add_children_items_iter == 0:
			return
		_add_children_items_iter -= 1
		
		var is_disabled: bool = false
		if node_type != '':
			is_disabled = !child.is_class(node_type)
		var _child: Node = add_node_item(parentItem, child, is_disabled)
		_add_children_items(child, _child, _add_children_items_iter)



func _on_checked_node(nodeItem: Control, child_id: int , value: bool):
	emit_signal("checked_node", nodeItem.node, child_id, value)
#	var node = nodeItem.node
#	var propertyBox: VBoxContainer = $"../../PropertyScroll/VBox"
#
#	if value:
#		propertyBox.insert_propertyDisplay(node, child_id)
#	else:
#		propertyBox.remove_propertyDisplay(node)
	

