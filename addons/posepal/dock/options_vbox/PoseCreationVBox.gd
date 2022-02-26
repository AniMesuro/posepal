tool
extends VBoxContainer

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var updateFromTemplateButton: Button
func _ready() -> void:
	updateFromTemplateButton = $UpdateFromTemplateButton
	
	updateFromTemplateButton.connect("pressed", self, "_on_UpdateFromTemplateButton")
	

func _on_UpdateFromTemplateButton():
	if owner.poselib_scene == '' or owner.poselib_template == '':
		return
	var selectedAnimPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(selectedAnimPlayer) or !is_instance_valid(poselib):
		return
	
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"
	var anim: Animation = selectedAnimPlayer.get_animation(poseCreationHBox.selected_animation)
	if !is_instance_valid(anim):
		return
	print('anim ',poseCreationHBox.selected_animation,' ',anim)
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	
	var templatePose: Dictionary = poselib.templateData[owner.poselib_template]
	for node_path in templatePose:
#		print('template ',owner.poselib_template,' ',node_path)
		for property in templatePose[node_path]:
			var tr_path: String = node_path+':'+property
			var tr = anim.find_track(tr_path)
			if tr == -1:
				continue
#			print(tr_path)
			anim.value_track_set_update_mode(tr, poselib.templateData[owner.poselib_template][node_path][property]['upmo'])
			var has_key: bool = anim.track_get_key_count(tr) > 0
			if has_key:
				if anim.track_get_key_transition(tr, 0) != 1.0: # Ignore transitions overriden by player
					continue
				anim.track_set_key_transition(tr, 0, poselib.templateData[owner.poselib_template][node_path][property]['out'])
#			
	
#	poselib.templateData[owner.poselib_template][node_path][property]['out']
#	poselib.templateData[owner.poselib_template][node_path][property]['upmo'])

