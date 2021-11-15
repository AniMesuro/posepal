tool
extends VBoxContainer

var title: String = "Node" setget _set_title
var display_id: int = -1
var node: Node setget _set_node
var node_nodepath: String setget _set_node_nodepath


func _set_node(new_node: Node):
	node = new_node
	title = node.name
	

func _set_title(new_title: String):
	title = new_title
	$"NodeTab/VBoxContainer/TabHBox/ExpandButton".text = title

func _set_node_nodepath(new_node_nodepath: String):
	node_nodepath = new_node_nodepath
	$"NodeTab/VBoxContainer/TabHBox".hint_tooltip = node_nodepath


