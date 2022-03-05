tool
extends CheckBox

func _ready() -> void:
	connect("pressed", self, "_on_pressed")

func _on_pressed():
	var nodesVBox: VBoxContainer = $"../../HSplitContainer/TreeScroll/VBox"
	var has_unchecked_nodes: bool = false
	for nodeItem in nodesVBox.get_children():
		if !nodeItem.get_node('CheckButton').pressed:
			has_unchecked_nodes = true
			break
			
	if has_unchecked_nodes:
		for nodeItem in nodesVBox.get_children():
			var checkButton: CheckButton = nodeItem.get_node('CheckButton')
			if !checkButton.pressed:
				checkButton.pressed = true
				nodeItem.emit_signal("checked_node", nodeItem, nodeItem.child_id, true)
				
		pressed = true
		return
	else:
		for nodeItem in nodesVBox.get_children():
			nodeItem.get_node('CheckButton').pressed = false
			nodeItem.emit_signal("checked_node", nodeItem, nodeItem.child_id, false)
		pressed = false
