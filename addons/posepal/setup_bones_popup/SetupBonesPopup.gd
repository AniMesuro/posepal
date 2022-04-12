tool
extends WindowDialog



var boneRelationshipData: Dictionary = {}

var poselib: Resource

var posepalDock: Control
func _enter_tree() -> void:
	show()
	poselib = posepalDock.current_poselib
	boneRelationshipData = poselib.boneRelationshipData.duplicate(false)
#	$"MarginContainer/VBoxContainer/HSplitContainer/PolygonScroll/VBox"

func _ready() -> void:
	$MarginContainer/VBoxContainer/OkButton.connect("pressed", self, "_on_OkButton_pressed")
	# LOAD FROM POSELIB

#func _on_BoneButton_pressed(bone_path: NodePath):
#	emit_signal("bone_selected", bone_path)
#	queue_free()
func update_bone_relationship(node_path: String, bone_path: String):
	boneRelationshipData[node_path] = bone_path

func _on_OkButton_pressed():
	# SAVE TO POSELIB
#	var polygonVBox: VBoxContainer = $"MarginContainer/VBoxContainer/HSplitContainer/PolygonScroll/VBox"
#	polygonVBox.poseSkeleton
	poselib.boneRelationshipData = boneRelationshipData
	queue_free()

