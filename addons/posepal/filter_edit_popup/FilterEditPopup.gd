tool
extends WindowDialog

var posepalDock: Control
var filterData: Array

func _enter_tree() -> void:
	show()

func _ready() -> void:
	var okButton: Button = $Margin/VBox/OkButton
	var nodeVBox: VBoxContainer = $"Margin/VBox/Scroll/NodeVBox"
	okButton.connect("pressed", self, "_on_OkButton_pressed")
	nodeVBox.connect("checked_node", self, "_on_NodeVBox_checked_node")

func _on_NodeVBox_checked_node(node: Node, child_id: int, value: bool):
	if value:
		pass
	pass

func _on_OkButton_pressed():
	var nodeVBox: VBoxContainer = $"Margin/VBox/Scroll/NodeVBox"
	for nodeItem in nodeVBox.get_children():
		pass
	queue_free()


