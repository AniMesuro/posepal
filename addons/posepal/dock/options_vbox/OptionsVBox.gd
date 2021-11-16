tool
extends VBoxContainer

const SCN_BatchKeyPopup: PackedScene = preload("res://addons/posepal/batch_key_popup/BatchKeyPopup.tscn")

var batchKeyBtn: Button
func _ready() -> void:
	batchKeyBtn = $"BatchKeyBtn"
	batchKeyBtn.connect("pressed", self, "_on_BatchKeyBtn_pressed")

func _on_BatchKeyBtn_pressed():
	# open batch key popup
	# should be disabled if no (generally) animationplayer selected and no poseroot selected.
	if owner.poselib_scene == '':
		print('[PosePal] poselib_scene not selected.')
		return
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	if currentAnimOptionButton.text == "":
		owner.issue_warning("animplayeredit_empty")
		return
		
	
	var current_edited_animPlayer: AnimationPlayer = null
	for selectedNode in editorSelection.get_selected_nodes():
		if selectedNode.get_class() != 'AnimationPlayer':
			continue
		var animPlayer: AnimationPlayer = selectedNode
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			current_edited_animPlayer = animPlayer
			break
	var newPoseButton: Button = $"../../../../ExtraHBox/PoseCreationVBox/NewPoseButton"
	
	if !is_instance_valid(currentAnimOptionButton):
		if is_instance_valid(newPoseButton.animationPlayer):
			current_edited_animPlayer = newPoseButton.animationPlayer
			
	if !is_instance_valid(currentAnimOptionButton):
		if is_instance_valid(owner.poselib_animPlayer):
			current_edited_animPlayer = owner.poselib_animPlayer
	
	if !is_instance_valid(currentAnimOptionButton):
		print('[PosePal] No AnimationPlayer found in AnimationPlayerEditor')
		return
#	else:
	print("batch key")
	batchKeyBtn = $"BatchKeyBtn"
	var batchKeyPopup: Control = SCN_BatchKeyPopup.instance()
	batchKeyPopup.posepalDock = owner
	batchKeyBtn.add_child(batchKeyPopup)
#	batchKeyPopup.owner = owner
	batchKeyPopup.current_edited_animPlayer = current_edited_animPlayer
#		batchKeyPopup.connect() # Batch keying issued.



