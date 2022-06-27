tool
extends WindowDialog

signal nodepath_selected (node_path)

var poselib: Resource

var posepalDock: Control
func _ready() -> void:
	$MarginCon/VBox/CancelButton.connect("pressed", self, "_on_CancelButton_pressed")

func _enter_tree() -> void:
	if get_tree().edited_scene_root != self:
		popup()

func _on_NodeButton_pressed(node_path: String):
	print('np ',node_path)
	emit_signal("nodepath_selected", node_path)
	queue_free()

func _on_CancelButton_pressed():
	queue_free()
