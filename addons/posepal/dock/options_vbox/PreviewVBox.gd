tool
extends VBoxContainer

func refresh():
	$IgnoreScenePoseChk.pressed = owner.optionsData.ignore_scene_pose
