tool
extends VBoxContainer

const SCN_BatchKeyPopup: PackedScene = preload("res://addons/posepal/batch_key_popup/BatchKeyPopup.tscn")

var is_pose_queued: bool = false setget _set_is_pose_queued

var batchKeyBtn: Button
var ignoreScenePoseChk: CheckBox
var dontKeyDuplicateChk: CheckBox
var keyTemplateChk: CheckBox
var sliceToggleAudioButton: Button
var queueKeyTime: Button
func _ready() -> void:
	batchKeyBtn = $"BatchKeyBtn"
	ignoreScenePoseChk = $"IgnoreScenePoseChk"
	dontKeyDuplicateChk = $"DontKeyDuplicateChk"
	keyTemplateChk = $"KeyTemplateChk"
	sliceToggleAudioButton = $"SliceToggleAudioButton" # remove
	queueKeyTime = $"QueueKeyTimeBtn"
	
	batchKeyBtn.connect("pressed", self, "_on_BatchKeyBtn_pressed")
	ignoreScenePoseChk.connect("pressed", self, "_on_IgnoreScenePoseChk_pressed")
	sliceToggleAudioButton.connect("pressed", self, "_on_SliceToggleAudioButton_pressed")
	dontKeyDuplicateChk.connect("pressed", self, "_on_DontKeyDuplicateChk_pressed")
	keyTemplateChk.connect("pressed", self, "_on_KeyTemplateChk_pressed")
	queueKeyTime.connect("pressed", self, "_on_QueueKeyTimeBtn_pressed")
	
	
	owner.connect('updated_reference', self, '_on_PoseLibrary_updated_reference')
	owner.connect("issued_forced_selection", self, "_on_issued_forced_selection")


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
	
	if !is_instance_valid(current_edited_animPlayer):
		# PoseAnimationPlayer should be child of NewPoseButton
		var poseButton_children: Array = newPoseButton.get_children()
		print("posebutton children ",poseButton_children)
		if poseButton_children.size() > 0:
			current_edited_animPlayer = newPoseButton.get_children()[0]
			
	if !is_instance_valid(current_edited_animPlayer):
		if is_instance_valid(owner.poselib_animPlayer):
			current_edited_animPlayer = owner.poselib_animPlayer
	
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

func _on_IgnoreScenePoseChk_pressed():
	ignoreScenePoseChk = $IgnoreScenePoseChk
	owner.optionsData.ignore_scene_pose = ignoreScenePoseChk.pressed
#	print('ignore',owner.optionsData.ignore_scene_pose)

# Not really animation in itself, but it helps lipsync.
func _on_SliceToggleAudioButton_pressed():
	owner.pluginInstance._get_editor_references()
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	if !is_instance_valid(selectedAnimationPlayer):
		return
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	var current_time: float = float(currentTimeLineEdit.text)
	print('slice audio, ',currentAnimationOptionButton.text, current_time)
	
	###### get the first track
	var tr_audio: int = -1
	for i in currentAnimation.get_track_count():
		if currentAnimation.track_get_type(i) != currentAnimation.TYPE_AUDIO:
			continue
		tr_audio = i
	if tr_audio == 1:
		print("[PosePal] Audio Track not found.")
		return
	
	#Get key
	var is_key_sliced_at_time: bool = false
	var key_exact_id = currentAnimation.track_find_key(tr_audio, current_time, true)
	var key_inexact_id = currentAnimation.track_find_key(tr_audio, current_time, false)
	print(key_exact_id,' ',current_time)
	
	# [X] found key not exactly at time.
	if (key_exact_id == -1 && key_inexact_id != -1):
		var audioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_inexact_id)
		var audio_key_time: float = currentAnimation.track_get_key_time(tr_audio, key_inexact_id)
		var audio_key_start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_inexact_id)
		var audioSample_length: float = _get_sample_length(audioSample)
		var new_key: int = currentAnimation.audio_track_insert_key(tr_audio, current_time, audioSample,
			(current_time - audio_key_time + audio_key_start_offset))
		
		currentAnimation.audio_track_set_key_end_offset(tr_audio, key_inexact_id,
			stepify(audioSample_length- (current_time - audio_key_time + audio_key_start_offset), .1))
#		(audioSample_length - current_time - audio_key_time + audio_key_start_offset))
		
	# found key at exact time and there's a key before
	elif (key_exact_id != -1 && (key_exact_id-1 > -1)):
		print('exact key and key before')
		var prevAudioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_exact_id - 1)
		var audioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_exact_id)
		var prevAudioKey_time: float = currentAnimation.track_get_key_time(tr_audio, key_exact_id - 1)
		var prevSample_full_length: float = _get_sample_length(prevAudioSample)
		print(prevSample_full_length)
		
		# Probably the same sample.
		if prevAudioSample.data == audioSample.data:
			print('both keys have same data')
			var prev_start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_exact_id-1)
			var prev_end_offset: float = currentAnimation.audio_track_get_key_end_offset(tr_audio, key_exact_id-1)
			var start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_exact_id)
			var end_offset: float = currentAnimation.audio_track_get_key_end_offset(tr_audio, key_exact_id)
			
			# 123|456
			
			#length of exact clip
			var sliced_length: float = prevSample_full_length - start_offset - end_offset
			
			# works if the previous clip doesnt have start offset only.
			currentAnimation.audio_track_set_key_end_offset(tr_audio, key_exact_id - 1, prev_end_offset - sliced_length)
			print('sliced length ',sliced_length)
			print('prevlength+ slicedlength ', prevSample_full_length - sliced_length)
			currentAnimation.track_remove_key(tr_audio, key_exact_id)
			
	#Check if audio is sliced or full
#	var end_offset = currentAnimation.audio_track_get_key_end_offset(tr_audio, key_id)
#	var start_offset = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_id)
	
#	Possibilities:
#	
#	123|456
#	   |123456
#	|123-
#	|456
#	123   |456
#	123456|123456

	
func _get_sample_length(sample: AudioStreamSample) -> float:
	return stepify(float(sample.data.size()) / (sample.mix_rate * 4), 0.01)

func _on_DontKeyDuplicateChk_pressed():
	owner.optionsData.dont_key_duplicate = $DontKeyDuplicateChk.pressed


func _on_KeyTemplateChk_pressed():
	owner.optionsData.key_template = $KeyTemplateChk.pressed
	print('options ',owner.optionsData)

func _on_QueueKeyTimeBtn_pressed():
	if get_posegen_mode() == 2: # SAVE - Editing pose.
		return
	if owner.poselib_scene == '':
		print('[PosePal] poselib_scene not selected.')
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
		

func refresh_ui():
	print('refreshed')
#	'ignore_scene_pose': false,
#	'key_template': false,
#	'dont_key_duplicate': false
	$IgnoreScenePoseChk.pressed = owner.optionsData.ignore_scene_pose
	$KeyTemplateChk.pressed = owner.optionsData.key_template
	$DontKeyDuplicateChk.pressed = owner.optionsData.dont_key_duplicate
	self.is_pose_queued = false

func _on_PoseLibrary_updated_reference(reference :String):
	if reference == 'poselib_scene':
#	if owner.get(reference) == '':
		refresh_ui()

func _on_issued_forced_selection():
	refresh_ui()
	
func get_posegen_mode() -> int:
	var poseCreationVBox = $"../../../../ExtraHBox/PoseCreationVBox"
	return poseCreationVBox.posegen_mode
