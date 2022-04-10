tool
extends VBoxContainer

signal checked_node (node, child_id, value)

const SCN_PolygonItem: PackedScene =  preload("res://addons/posepal/setup_bones_popup/PolygonItem.tscn")

var poseSceneRoot: Node
func _ready() -> void:
	if owner == get_tree().edited_scene_root:
		return
	fill_nodes()

func clear_tree():
	for child in get_children():
		child.queue_free()

func fill_nodes(type: String = ''):
	clear_tree()
	if !is_inside_tree():
		return
	if get_tree().edited_scene_root == owner:
		return
		
	var editedSceneRoot = get_tree().edited_scene_root
	poseSceneRoot = editedSceneRoot.get_node_or_null(owner.posepalDock.poselib_scene)
	if !is_instance_valid(poseSceneRoot):
		return
		
	var _poseSceneRoot: Control = add_node_item(null, poseSceneRoot)
	_add_children_items(poseSceneRoot, _poseSceneRoot, 400)


func add_node_item(parentItem: Node, node: Node, disabled: bool = false) -> Node:
	var nodeItem: HBoxContainer = SCN_PolygonItem.instance()
	nodeItem.node_name = node.name
	nodeItem.node = node
	nodeItem.parentItem = parentItem
	nodeItem.child_id = get_child_count()
	add_child(nodeItem)
	nodeItem.node_type = node.get_class()
	nodeItem.is_expanded = true
#	nodeItem.connect("checked_node", self, "_on_checked_node")
	
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
		
		var _child: Node = add_node_item(parentItem, child)
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
	
