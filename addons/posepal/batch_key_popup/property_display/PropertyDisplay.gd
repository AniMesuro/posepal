tool
extends VBoxContainer

const SCN_PropertyItem: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyItem.tscn")

var title: String = "Node" setget _set_title
var display_id: int = -1
var node: Node setget _set_node
var node_nodepath: String setget _set_node_nodepath

var is_valid_for_batch_property: bool = false setget _set_is_valid_for_batch_property

func add_propertyItem(text: String):
	# Instance PropertyItem
	# Only if property valid on Node.
	var propertyItem: Control = SCN_PropertyItem.instance()
	var lineEdit: LineEdit = $"NodeTab/VBoxContainer/AddHBox/LineEdit"
#	print('aaaaaaa ',propertyItem.property)
	var propertyContainer: GridContainer = $"PropertyContainer"
	propertyContainer.add_child(propertyItem)
	propertyItem.property = text
	lineEdit.text = ""

func get_properties() -> PoolStringArray:
	var properties: PoolStringArray = []
	var propertyContainer: GridContainer = $"PropertyContainer"
	for propertyItem in propertyContainer.get_children():
		properties.append(propertyItem.property)
	return properties
		

func validate_batch_property(batch_property: String) -> bool:
	is_valid_for_batch_property = false
	if (batch_property in node):
		if !batch_property in get_properties():
			self.is_valid_for_batch_property = true
	else:
		self.is_valid_for_batch_property = false
	return is_valid_for_batch_property

func _set_node(new_node: Node):
	node = new_node
	title = node.name
	

func _set_title(new_title: String):
	title = new_title
	$"NodeTab/VBoxContainer/TabHBox/ExpandButton".text = title

func _set_node_nodepath(new_node_nodepath: String):
	node_nodepath = new_node_nodepath
	$"NodeTab/VBoxContainer/TabHBox".hint_tooltip = node_nodepath

func _set_is_valid_for_batch_property(new_is_valid_for_batch_property: bool):
	is_valid_for_batch_property = new_is_valid_for_batch_property
	$"NodeTab/VBoxContainer/TabHBox/BatchValidIcon".visible = is_valid_for_batch_property


