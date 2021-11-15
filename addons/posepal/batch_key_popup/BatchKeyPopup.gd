tool
extends Popup


const TEX_Icon: StreamTexture = preload("res://addons/posepal/plugin_icon.png")
#onready var itemTree: Tree = $"MarginContainer/VBox/HSplitContainer/ScrollContainer2/Tree"

var posepalDock: Control
func _enter_tree() -> void:
	
	show()

func _ready() -> void:
	
	# Load scene tree on nodeVBox
	pass


#	var root = add_tree_item(null, "Neck")
#	var head = add_tree_item(root, "Head")
#	var hair = add_tree_item(head, "Hair")
#	var eyes = add_tree_item(head, "Eyes")
#	var mouth = add_tree_item(head, "Mouth")

#func add_tree_item(parent: Node, text: String) -> TreeItem:
#	var treeItem = itemTree.create_item(parent)
#	treeItem.set_text(0, text)
#	treeItem.set_icon_max_width(0, 32)
#	treeItem.set_icon(0, TEX_Icon)
#	treeItem.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
#	treeItem.set_selectable(0, true)
#	treeItem.set_checked(0, true)
#	treeItem.set_editable(1, true)
#	treeItem.set_expand_right(1, true)
#	return treeItem
