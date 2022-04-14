tool
extends VBoxContainer

func _ready() -> void:
	owner.pluginInstance.connect("scene_changed", self, "_on_scene_changed")
	$IgnoreScenePoseChk.connect("pressed", self, "_on_IgnoreScenePoseChk_pressed")
	$ShowBonesChk.connect("pressed", self, "_on_ShowBonesChk_pressed")

func refresh():
	$IgnoreScenePoseChk.pressed = owner.optionsData.ignore_scene_pose
	$ShowBonesChk.pressed = owner.optionsData.show_bones

func _on_IgnoreScenePoseChk_pressed():
	owner.optionsData.ignore_scene_pose = $IgnoreScenePoseChk.pressed

func _on_ShowBonesChk_pressed():
	var showBonesChk: CheckBox = $ShowBonesChk
	owner.optionsData.show_bones = showBonesChk.pressed

func _on_scene_changed(_sceneRoot: Node):
	owner.optionsData['ignore_scene_pose'] = false
	owner.optionsData['show_bones'] = false
	refresh()
