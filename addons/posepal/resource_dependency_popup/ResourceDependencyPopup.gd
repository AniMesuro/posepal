tool
extends WindowDialog

signal ok_pressed (has_missing_dependencies)

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var old_paths: PoolStringArray = []
var is_first_time: bool = true

var posePalDock: Control
var poselib: RES_PoseLibrary

func _enter_tree() -> void:
	visible = true
	if !is_first_time:
		return
	is_first_time = false
	
	if get_tree().edited_scene_root == self:
		return
	if !is_instance_valid(posePalDock):
		queue_free()
		return
	if !is_instance_valid(posePalDock.currentPoselib):
		queue_free()
		return
		
	popup_centered()
	poselib = posePalDock.currentPoselib
	old_paths = poselib.get_res_paths()

func _ready() -> void:
	$MarginCon/VBox/OkHBox/OkButton.connect("pressed", self, "_on_OkButton_pressed")

func _on_OkButton_pressed():
	var has_broken: bool = _resolve_dependencies()
	posePalDock.save_poseData()
	emit_signal("ok_pressed", has_broken)
	queue_free()

func fix_warning():
	$"MarginCon/VBox/OkHBox/WarningIcon".visible = false

func _resolve_dependencies() -> bool:
	var fileVBox: VBoxContainer = $"MarginCon/VBox/VBox/ScrollCon/FileVBox"
	var f: File = File.new()
	var poselib: RES_PoseLibrary = posePalDock.currentPoselib
	var has_broken_dependencies: bool = false
	
	for k in poselib.resourceReferences.keys():
		var res_path = poselib.resourceReferences[k]
		if !fileVBox.children_as_dict.has(k):
			continue
		if res_path != fileVBox.children_as_dict[k].old_path:
			continue
		var new_path = fileVBox.children_as_dict[k].new_path
		if !f.file_exists(new_path):
			has_broken_dependencies = true
			continue
		poselib.resourceReferences[k] = new_path
	return has_broken_dependencies
