tool
extends WindowDialog

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var old_paths: PoolStringArray = []
var unfixed_nodepaths_num: int = 0 setget _set_unfixed_nodepaths_num
var is_first_time: bool = true

var posepalDock: Control
var poselib: RES_PoseLibrary

func _enter_tree() -> void:
	if get_tree().edited_scene_root != self:
		popup_centered(Vector2(OS.window_size.x* .4, OS.window_size.y-20))
	else:
		show()
	if !is_instance_valid(posepalDock):
		return
	poselib = posepalDock.currentPoselib

func _ready() -> void:
	$"MarginCon/VBox/OkHBox/OkButton".connect("pressed", self, "_on_OkButton_pressed")

func _on_OkButton_pressed():
	var nodepathVBox: VBoxContainer = $"MarginCon/VBox/VBox/ScrollCon/NodepathVBox"
	for nodepathItem in nodepathVBox.get_children():
		poselib.nodepathReferences[nodepathItem.np_id] = nodepathItem.new_path
	posepalDock.save_poseData()
	queue_free()

func _set_unfixed_nodepaths_num(new_unfixed_nodepaths_num):
	unfixed_nodepaths_num = new_unfixed_nodepaths_num
	if unfixed_nodepaths_num < 1:
		$"MarginCon/VBox/OkHBox/WarningIcon".visible = false
		return
	$"MarginCon/VBox/OkHBox/WarningIcon".visible = true


