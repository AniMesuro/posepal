tool
extends VBoxContainer

var title: String = "Node" setget _set_title
var display_id: int = -1
var node: Node setget _set_node

func _set_node(new_node: Node):
	node = new_node
	title = node.name

func _set_title(new_title: String):
	title = new_title
	$"NodeTab/TabHBox/Label".text = title
