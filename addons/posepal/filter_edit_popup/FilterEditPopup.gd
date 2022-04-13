tool
extends WindowDialog

var posepalDock: Control
var filterData: Array

var poseSceneRoot: Node
func _enter_tree() -> void:
	show()

func _ready() -> void:
	var okButton: Button = $Margin/VBox/OkButton
	var nodeVBox: VBoxContainer = $"Margin/VBox/Scroll/NodeVBox"
	okButton.connect("pressed", self, "_on_OkButton_pressed")
	nodeVBox.connect("checked_node", self, "_on_NodeVBox_checked_node")
	poseSceneRoot = nodeVBox.poseSceneRoot#get_tree().edited_scene_root.get_node_or_null(posepalDock.poselib_scene)
#	print('poseRoot ',poseSceneRoot)
	_load_filter()

func _load_filter():
#	print('loading filter ',filterData)
	var nodeVBox: VBoxContainer = $"Margin/VBox/Scroll/NodeVBox"
	for nodeItem in nodeVBox.get_children():
		var nodepath: String = poseSceneRoot.get_path_to(nodeItem.node)
		if filterData.has(nodepath):
			nodeItem.get_node('CheckButton').pressed = true

func _on_NodeVBox_checked_node(node: Node, child_id: int, value: bool):
	var nodepath: String = poseSceneRoot.get_path_to(node)
	if value:
		if filterData.has(nodepath):
			return
		filterData.append(nodepath)
	else:
		filterData.erase(nodepath)
#	print('filterdata ',filterData)

func _on_OkButton_pressed():
	posepalDock.current_poselib.filterData[posepalDock.poselib_filter] = filterData
	queue_free()


