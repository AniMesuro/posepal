tool
extends VBoxContainer

const SCN_BatchKeyPopup: PackedScene = preload("res://addons/posepal/batch_key_popup/BatchKeyPopup.tscn")

var is_pose_queued: bool = false setget _set_is_pose_queued

var batchKeyBtn: Button
var queueKeyTime: Button

var dontKeyDuplicateChk: CheckBox
var keyTemplateChk: CheckBox

func _ready() -> void:
	batchKeyBtn = $"BatchKeyBtn"
	dontKeyDuplicateChk = $"DontKeyDuplicateChk"
	queueKeyTime = $"QueueKeyTimeBtn"
	keyTemplateChk = $"KeyTemplateChk"
	
	batchKeyBtn.connect("pressed", self, "_on_BatchKeyBtn_pressed")
	dontKeyDuplicateChk.connect("pressed", self, "_on_DontKeyDuplicateChk_pressed")
	keyTemplateChk.connect("pressed", self, "_on_KeyTemplateChk_pressed")
	queueKeyTime.connect("pressed", self, "_on_QueueKeyTimeBtn_pressed")

func _on_KeyTemplateChk_pressed():
	owner.optionsData.key_template = $KeyTemplateChk.pressed
	print('options ',owner.optionsData)

func _on_QueueKeyTimeBtn_pressed():
	if get_parent().get_posegen_mode() == 2: # SAVE - Editing pose.
		return
	if (owner.poselib_scene == '' or owner.poselib_filter == ''
	or  owner.poselib_template == '' or owner.poselib_collection == ''):
		return
	# check if animation is selected.
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	if !is_instance_valid(selectedAnimationPlayer):
		return
		
	if is_pose_queued:
		var tr_queue_keys: int = currentAnimation.find_track(selectedAnimationPlayer.name+':editor_description')
		if tr_queue_keys != -1:
			currentAnimation.remove_track(tr_queue_keys)
		self.is_pose_queued = false
		return
	owner.pluginInstance._get_editor_references()
	
	print('queues')
	var current_time: float = float(currentTimeLineEdit.text)
	
	
	var tr_queue_keys: int = currentAnimation.find_track(selectedAnimationPlayer.name+':editor_description')
	if tr_queue_keys == -1:
		tr_queue_keys = currentAnimation.add_track(Animation.TYPE_VALUE, 0)
		currentAnimation.track_set_path(tr_queue_keys, selectedAnimationPlayer.name+':editor_description')
	currentAnimation.track_insert_key(tr_queue_keys, current_time, "queue", 0)
	
	# Save a temporary pose with every property from tracks,
	# But when keyed only the changed keys will be keyd.
	owner.queuedPoseData = {}
	var animRootNode: Node = selectedAnimationPlayer.get_node(selectedAnimationPlayer.root_node)
	var _animPlayer_path: String = str(animRootNode.get_path_to(selectedAnimationPlayer))
	print('animrootnode ',animRootNode)
	for tr in currentAnimation.get_track_count():
		var track_path: NodePath = currentAnimation.track_get_path(tr) # (@@@)/./Sprite:position
		var path_subnames: NodePath = track_path.get_concatenated_subnames() # :position
		var node_path: String = str(track_path).trim_suffix(str(path_subnames)).rstrip(':') # Sprite
		if node_path == '':
			node_path = '.'
		if node_path == _animPlayer_path:
			continue
#		print('_n ',node_path)
#		print(node_path)
#		print('_nodenode ',animRootNode.get_node(node_path))
#		break
#		var node_path: String = str(track_path).rstrip(str(path_subnames)).rstrip(':') # position
		if !owner.queuedPoseData.has(node_path):
			owner.queuedPoseData[node_path] = {}
		owner.queuedPoseData[node_path][path_subnames] = animRootNode.get_node(node_path).get(path_subnames)
#		print('quedposedata ',node_path,' ',path_subnames)
		
#		owner.queuedPoseData[track_path] = animRootNode.get_node(node_path).get(path_subnames)
#		print(track_path,' | ', owner.queuedPoseData[track_path])
		
	owner.queued_key_time = current_time
	self.is_pose_queued = true
	print('queusize ',owner.queuedPoseData.size())



	


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
		
	
	var current_edited_animPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	
#	for selectedNode in editorSelection.get_selected_nodes():
#		if selectedNode.get_class() != 'AnimationPlayer':
#			continue
#		var animPlayer: AnimationPlayer = selectedNode
#		if animPlayer.assigned_animation == currentAnimOptionButton.text:
#			current_edited_animPlayer = animPlayer
#			break
	var newPoseButton: Button = $"../../../../../../ExtraHBox/PoseCreationHBox/NewPoseButton"
	
	
#	if !is_instance_valid(current_edited_animPlayer):
#		# PoseAnimationPlayer should be child of NewPoseButton
#		var poseButton_children: Array = newPoseButton.get_children()
#		print("posebutton children ",poseButton_children)
#		if poseButton_children.size() > 0:
#			current_edited_animPlayer = newPoseButton.get_children()[0]
			
#	if !is_instance_valid(current_edited_animPlayer):
#		if is_instance_valid(owner.poselib_animPlayer):
#			current_edited_animPlayer = owner.poselib_animPlayer
	
	if !is_instance_valid(current_edited_animPlayer):
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

func _on_DontKeyDuplicateChk_pressed():
	owner.optionsData.dont_key_duplicate = $DontKeyDuplicateChk.pressed

func refresh():
	if !is_instance_valid(self):
#	if !is_inside_tree():
		return
	$KeyTemplateChk.pressed = owner.optionsData.key_template
	$DontKeyDuplicateChk.pressed = owner.optionsData.dont_key_duplicate
	self.is_pose_queued = false

func _set_is_pose_queued(new_is_pose_queued: bool):
	is_pose_queued = new_is_pose_queued
	queueKeyTime = $"QueueKeyTimeBtn"
	if is_pose_queued:
		queueKeyTime.text = "Cancel queued pose"
	else:
		queueKeyTime.text = "Queue key at time"
		owner.queuedPoseData = {}
		owner.queued_key_time = -1.0
		
		var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
		if !is_instance_valid(selectedAnimationPlayer):
			return
		var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
		var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
		var tr_queue_keys: int = currentAnimation.find_track(selectedAnimationPlayer.name+':editor_description')
		if tr_queue_keys != -1:
			currentAnimation.remove_track(tr_queue_keys)
