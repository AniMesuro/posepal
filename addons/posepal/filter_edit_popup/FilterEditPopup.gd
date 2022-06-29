tool
extends WindowDialog

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var posepalDock: Control
var filterData: Array

var poseSceneRoot: Node
var poselib: RES_PoseLibrary
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
		var np_id: int = poselib.get_id_from_nodepath(nodepath)
		if filterData.has(np_id):
			nodeItem.get_node('CheckButton').pressed = true

func _on_NodeVBox_checked_node(node: Node, child_id: int, value: bool):
	var nodepath: String = poseSceneRoot.get_path_to(node)
	var np_id: int = poselib.get_id_from_nodepath(nodepath)
	if value:
		if filterData.has(np_id):
			return
		filterData.append(np_id)
	else:
		filterData.erase(np_id)
#	print('filterdata ',filterData)

func _on_OkButton_pressed():
	posepalDock.currentPoselib.filterData[posepalDock.poselib_filter] = filterData
	queue_free()


