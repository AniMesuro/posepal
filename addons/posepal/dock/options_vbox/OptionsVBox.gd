tool
extends VBoxContainer

const RES_PosePalSettings: GDScript = preload("res://addons/posepal/PosePalSettings.gd")

var ignoreScenePoseChk: CheckBox

func _ready() -> void:
	ignoreScenePoseChk = $"PreviewVBox/IgnoreScenePoseChk"
	
	
	owner.connect('updated_reference', self, '_on_PoseLibrary_updated_reference')
	owner.connect("issued_forced_selection", self, "_on_issued_forced_selection")

	var settings: RES_PosePalSettings = owner.pluginInstance.settings
	if settings.debug_mode == settings.BoolToggle.on:
		$"MiscColumn".is_locked = false
	else:
		$"MiscColumn".is_locked = true


func refresh_ui():
	$KeyingVBox.refresh()
	$PreviewVBox.refresh()
	$MiscVBox.refresh()

func _on_PoseLibrary_updated_reference(reference :String):
	if reference == 'poselib_scene':
		refresh_ui()

func _on_issued_forced_selection():
	refresh_ui()
	
func get_posegen_mode() -> int:
	var poseCreationHBox: HBoxContainer = $"../../../../../ExtraHBox/PoseCreationHBox"
	return poseCreationHBox.posegen_mode
