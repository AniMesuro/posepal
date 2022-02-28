tool
extends WindowDialog

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var old_paths: PoolStringArray = []
var new_paths: PoolStringArray = []

var posePalDock: Control

var is_first_time: bool = true
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
	if !is_instance_valid(posePalDock.current_poselib):
		queue_free()
		return
	popup_centered()
	var poselib: RES_PoseLibrary = posePalDock.current_poselib
	old_paths = poselib.get_res_paths()

func _ready() -> void:
	$MarginCon/VBox/OkButton.connect("pressed", self, "_on_OkButton_pressed")

func _on_OkButton_pressed():
	_resolve_dependencies()
	queue_free()

func _resolve_dependencies():
	var fileVBox: VBoxContainer = $"MarginCon/VBox/VBox/ScrollCon/FileVBox"
	var f: File = File.new()
	var poselib: RES_PoseLibrary = posePalDock.current_poselib
	for i in poselib.resourceReferences.size():
		var res_pair = poselib.resourceReferences[i]
		if res_pair[poselib.ReferenceType.PATH] != old_paths[i]:
			continue
		var new_path = fileVBox.get_child(i).new_path
		if !f.file_exists(new_path):
			continue
		res_pair[poselib.ReferenceType.PATH] = new_path
	
	print('resolved dependencies ',poselib.resourceReferences)
	
