tool
extends WindowDialog

signal bone_selected (bone_path)

var skeletonRoot: Skeleton2D

var posepalDock: Control
func _enter_tree() -> void:
	show()
	$"Margin/VBox/Scroll/BoneVBox".poseRoot = skeletonRoot


func _fill_bones():
	pass

func _on_BoneButton_pressed(bone_path: String):
	emit_signal("bone_selected", bone_path)
	queue_free()
