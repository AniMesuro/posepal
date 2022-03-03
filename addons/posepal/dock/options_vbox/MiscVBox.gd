tool
extends VBoxContainer

const SCN_ResourceDependencyPopup: PackedScene = preload("res://addons/posepal/resource_dependency_popup/ResourceDependencyPopup.tscn") 


#var sliceToggleAudioButton: Button
func _ready() -> void:
	$FileDependencyButton.connect("pressed", self, "_on_FileDependencyButton_pressed")
	$SliceToggleAudioButton.connect("pressed", self, "_on_SliceToggleAudioButton_pressed")
	$ClearTracksButton.connect("pressed", self, "_on_ClearTracksButton_pressed")
	$ClearTracksButton/ConfirmationDialog.connect("confirmed", self, "_on_ClearTracksButton_confirmed")

func _on_FileDependencyButton_pressed():
	if owner.poselib_scene == '':
		return
	var resourceDependencyPopup: Control = SCN_ResourceDependencyPopup.instance()
	resourceDependencyPopup.posePalDock = owner
	$FileDependencyButton.add_child(resourceDependencyPopup)
	
# Not really animation in itself, but it helps lipsync.
func _on_SliceToggleAudioButton_pressed():
	owner.pluginInstance._get_editor_references()
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	if !is_instance_valid(selectedAnimationPlayer):
		return
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	if currentAnimationOptionButton.text == "":
		owner.issue_warning("animplayeredit_empty")
		return
	
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	var current_time: float = float(currentTimeLineEdit.text)
#	print('slice audio, ',currentAnimationOptionButton.text, current_time)
	
	###### get the first track
	var tr_audio: int = -1
	for i in currentAnimation.get_track_count():
		if currentAnimation.track_get_type(i) != currentAnimation.TYPE_AUDIO:
			continue
		tr_audio = i
	if tr_audio == -1:
		print("[posepal] Audio Track not found.")
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


func _on_ClearTracksButton_pressed():
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	if !is_instance_valid(selectedAnimationPlayer):
		print('[posepal] AnimPlayer not referenced succesfully.')
		return
	if currentAnimationOptionButton.text == "":
		return
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	if currentAnimation.get_track_count() == 0:
		return
	
	var confirmationDialog: ConfirmationDialog = $ClearTracksButton/ConfirmationDialog
	confirmationDialog.popup_centered()
	

func _on_ClearTracksButton_confirmed():
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	currentAnimation.clear()

func _get_sample_length(sample: AudioStreamSample) -> float:
	return stepify(float(sample.data.size()) / (sample.mix_rate * 4), 0.01)
