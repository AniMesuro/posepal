tool
extends VBoxContainer

const SCN_CustomScene: PackedScene = preload("res://addons/posepal/custom_pose/CustomPose.tscn")

var batchKeyBtn: Button
func _ready() -> void:
	batchKeyBtn = $"BatchKeyBtn"
	batchKeyBtn.connect("pressed", self, "_on_BatchKeyBtn_pressed")

func _on_BatchKeyBtn_pressed():
	# open batch key popup
	# should be disabled if no animationplayer selected.
	pass
	if owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text == "":
		owner.issue_warning("animplayeredit_empty")
	else:
		print("batch key")
		var batchKeyPopup: Control = SCN_CustomScene.instance()
		batchKeyPopup.posepalDock = owner
		batchKeyBtn.add_child(batchKeyPopup)
		batchKeyPopup.owner = owner
#		batchKeyPopup.connect() # Batch keying issued.



