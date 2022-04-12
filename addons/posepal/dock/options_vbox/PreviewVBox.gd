tool
extends VBoxContainer

func _ready() -> void:
	owner.pluginInstance.connect("scene_changed", self, "_on_scene_changed")

func refresh():
	$IgnoreScenePoseChk.pressed = owner.optionsData.ignore_scene_pose

func _on_scene_changed(_sceneRoot: Node):
	owner.optionsData['ignore_scene_pose'] = false
	refresh()
