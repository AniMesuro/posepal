tool
extends VBoxContainer


var ignoreScenePoseChk: CheckBox



func _ready() -> void:
#	batchKeyBtn = $"BatchKeyBtn"
	ignoreScenePoseChk = $"PreviewVBox/IgnoreScenePoseChk"
	ignoreScenePoseChk.connect("pressed", self, "_on_IgnoreScenePoseChk_pressed")
	
	owner.connect('updated_reference', self, '_on_PoseLibrary_updated_reference')
	owner.connect("issued_forced_selection", self, "_on_issued_forced_selection")

	if owner.debug_mode:
		$"MiscColumn".is_locked = false
	else:
		$"MiscColumn".is_locked = true


func _on_IgnoreScenePoseChk_pressed():
	ignoreScenePoseChk = $PreviewVBox/IgnoreScenePoseChk
	owner.optionsData.ignore_scene_pose = ignoreScenePoseChk.pressed
#	print('ignore',owner.optionsData.ignore_scene_pose)


	





func refresh_ui():
	print('refreshed')
	$KeyingVBox.refresh()
#	$PoseCreationVBox.refresh()
	$PreviewVBox.refresh()

func _on_PoseLibrary_updated_reference(reference :String):
	if reference == 'poselib_scene':
#	if owner.get(reference) == '':
		refresh_ui()

func _on_issued_forced_selection():
	refresh_ui()
	
func get_posegen_mode() -> int:
	var poseCreationHBox: HBoxContainer = $"../../../../../ExtraHBox/PoseCreationHBox"
	return poseCreationHBox.posegen_mode
