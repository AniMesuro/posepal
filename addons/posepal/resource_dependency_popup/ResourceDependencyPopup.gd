tool
extends WindowDialog

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
	var poselib: Resource = posePalDock.current_poselib
	$MarginCon/VBox/VBox/ScrollCon/FileVBox.old_paths = poselib.get_res_paths()

