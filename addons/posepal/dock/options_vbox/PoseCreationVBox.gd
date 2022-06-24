tool
extends VBoxContainer

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var updateFromTemplateButton: Button
func _ready() -> void:
	$UpdateFromTemplateButton.connect("pressed", self, "_on_UpdateFromTemplateButton_pressed")
	$DefaultUpdateModeButton.connect("pressed", self, "_on_DefaultUpdateModeButton_pressed")
	$"../PoseCreationColumn".connect("is_locked_changed", self, "_on_is_locked_changed")

func refresh():
	# make invisible if template editing. 
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"
	if poseCreationHBox.current_pose_type == poseCreationHBox.PoseType.TEMPLATE:
		$UpdateFromTemplateButton.visible = false
	else:
		$UpdateFromTemplateButton.visible = true

func _on_UpdateFromTemplateButton_pressed():
	if owner.poselib_scene == '' or owner.poselib_template == '':
		return
	var selectedAnimPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(selectedAnimPlayer) or !is_instance_valid(poselib):
		return
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"
	var anim: Animation = selectedAnimPlayer.get_animation(poseCreationHBox.selected_animation)
	if !is_instance_valid(anim):
		return
		
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	
	var templatePose: Dictionary = poselib.templateData[owner.poselib_template]
	for node_path in templatePose:
		for property in templatePose[node_path]:
			var tr_path: String = node_path+':'+property
			var tr = anim.find_track(tr_path)
			if tr == -1:
				continue
			anim.value_track_set_update_mode(tr, poselib.templateData[owner.poselib_template][node_path][property]['upmo'])
			var has_key: bool = anim.track_get_key_count(tr) > 0
			if has_key:
				if anim.track_get_key_transition(tr, 0) != 1.0: # Ignore transitions overriden by player
					continue
				anim.track_set_key_transition(tr, 0, poselib.templateData[owner.poselib_template][node_path][property]['out'])

func _on_DefaultUpdateModeButton_pressed():
	if owner.poselib_scene == '' or owner.poselib_template == '':
		return
	var selectedAnimPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(selectedAnimPlayer) or !is_instance_valid(poselib):
		return
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"
	var anim: Animation = selectedAnimPlayer.get_animation(poseCreationHBox.selected_animation)
	if !is_instance_valid(anim):
		return
		
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	
	var templatePose: Dictionary = poselib.templateData[owner.poselib_template]
	for i in anim.get_track_count():
		var track_path: NodePath = anim.track_get_path(i) # (@@@)/./Sprite:position
		var path_subnames: NodePath = track_path.get_concatenated_subnames() # :position
		var node_path: String = str(track_path).rstrip(str(path_subnames)).rstrip(':') # position
		var node: Node = poseSceneRoot.get_node(node_path)
		
		var property: String = track_path.get_subname(0)
		var update_mode: int = owner.get_default_update_mode(property)
		anim.value_track_set_update_mode(i, update_mode)

#	for node_path in templatePose:
#		for property in templatePose[node_path]:
#			templatePose[node_path]
	
func _on_is_locked_changed(value: bool):
	if value: 
		return
	refresh()
