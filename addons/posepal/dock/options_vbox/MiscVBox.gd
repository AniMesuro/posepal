tool
extends VBoxContainer

const SCN_ResourceDependencyPopup: PackedScene = preload("res://addons/posepal/resource_dependency_popup/ResourceDependencyPopup.tscn") 

func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	$FileDependencyButton.connect("pressed", self, "_on_FileDependencyButton_pressed")
	$SliceToggleAudioButton.connect("pressed", self, "_on_SliceToggleAudioButton_pressed")
	$ClearTracksButton.connect("pressed", self, "_on_ClearTracksButton_pressed")
	$ClearTracksButton/ConfirmationDialog.connect("confirmed", self, "_on_ClearTracksButton_confirmed")
	$SortTracksButton.connect("pressed", self, "_on_SortTracksButton_pressed")

func refresh():
	var settings: Resource = owner.pluginInstance.settings
	if settings.debug_mode == settings.BoolToggle.on:
		
		$"../MiscColumn".is_locked = false
	else:
		$"../MiscColumn".is_locked = true

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
	var tr_audio: int = -1
	for i in currentAnimation.get_track_count():
		if currentAnimation.track_get_type(i) != currentAnimation.TYPE_AUDIO:
			continue
		tr_audio = i
	if tr_audio == -1:
		print("[posepal] Audio Track not found.")
		return
	
	var is_key_sliced_at_time: bool = false
	var key_exact_id = currentAnimation.track_find_key(tr_audio, current_time, true)
	var key_inexact_id = currentAnimation.track_find_key(tr_audio, current_time, false)
	
	if (key_exact_id == -1 && key_inexact_id != -1):
		var audioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_inexact_id)
		var audio_key_time: float = currentAnimation.track_get_key_time(tr_audio, key_inexact_id)
		var audio_key_start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_inexact_id)
		var audioSample_length: float = _get_sample_length(audioSample)
		var new_key: int = currentAnimation.audio_track_insert_key(tr_audio, current_time, audioSample,
			(current_time - audio_key_time + audio_key_start_offset))
		
		currentAnimation.audio_track_set_key_end_offset(tr_audio, key_inexact_id,
			stepify(audioSample_length- (current_time - audio_key_time + audio_key_start_offset), .1))
		
	# found key at exact time and there's a key before
	elif (key_exact_id != -1 && (key_exact_id-1 > -1)):
		var prevAudioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_exact_id - 1)
		var audioSample: AudioStreamSample = currentAnimation.audio_track_get_key_stream(tr_audio, key_exact_id)
		var prevAudioKey_time: float = currentAnimation.track_get_key_time(tr_audio, key_exact_id - 1)
		var prevSample_full_length: float = _get_sample_length(prevAudioSample)
		print(prevSample_full_length)
		
		# Probably the same sample.
		if prevAudioSample.data == audioSample.data:
			var prev_start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_exact_id-1)
			var prev_end_offset: float = currentAnimation.audio_track_get_key_end_offset(tr_audio, key_exact_id-1)
			var start_offset: float = currentAnimation.audio_track_get_key_start_offset(tr_audio, key_exact_id)
			var end_offset: float = currentAnimation.audio_track_get_key_end_offset(tr_audio, key_exact_id)
			
			#length of exact clip
			var sliced_length: float = prevSample_full_length - start_offset - end_offset
			
			currentAnimation.audio_track_set_key_end_offset(tr_audio, key_exact_id - 1, prev_end_offset - sliced_length)
			currentAnimation.track_remove_key(tr_audio, key_exact_id)

func _on_ClearTracksButton_pressed():
	if !is_instance_valid(owner.pluginInstance):
		return
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
	if !is_instance_valid(selectedAnimationPlayer):
		return
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	currentAnimation.clear()

func _on_SortTracksButton_pressed():
	var selectedAnimationPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	if !is_instance_valid(selectedAnimationPlayer):
		return
	var currentAnimationOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentAnimation: Animation = selectedAnimationPlayer.get_animation(currentAnimationOptionButton.text)
	if !is_instance_valid(currentAnimation):
		return
	var animRoot: Node = selectedAnimationPlayer.get_node(selectedAnimationPlayer.root_node)
	
	_append_children_to_array(get_tree().edited_scene_root, animRoot, 100)
	var unsorted_tracks: Dictionary = {} # 2: ["Head/Eyes", "Head/Eyes:position"]
	var sorted_tracks: Array = []
	
	for tr in currentAnimation.get_track_count():
		var full_path: String = currentAnimation.track_get_path(tr)
		var node_path: String = full_path.split(':')[0]
		
		var scene_pos: int = _animRoot_scene_paths.find(node_path)
		if scene_pos == -1:
			continue
		
		if !unsorted_tracks.has(scene_pos):
			unsorted_tracks[scene_pos] = [node_path, full_path]
		else:
			unsorted_tracks[scene_pos].append(full_path)
	
	var sorted_scene_positions: PoolIntArray = _sort_numbers(unsorted_tracks.keys(), false)
	for i in sorted_scene_positions.size():
		var scene_pos = sorted_scene_positions[i]
		var node_path = unsorted_tracks[scene_pos][0]
		
		for j in range(1, unsorted_tracks[scene_pos].size()):
			var full_path: String = unsorted_tracks[scene_pos][j]
			sorted_tracks.append(full_path)
	
	for i in sorted_tracks.size():
		var full_path: String = sorted_tracks[i]
		
		var tr: int = currentAnimation.find_track(full_path)
		currentAnimation.track_move_to(tr, i)

func _sort_numbers(numbers: Array, allow_duplicates: bool = true):
	var unsorted_numbers: PoolIntArray = numbers
	var sorted_numbers: PoolIntArray = [unsorted_numbers[0]]
	for unsorted_num in unsorted_numbers:
		for i in sorted_numbers.size():
			if unsorted_num > sorted_numbers[i]:
				if (i == sorted_numbers.size()-1) :
					sorted_numbers.append(unsorted_num)
					break
				elif unsorted_num < sorted_numbers[i+1]:
					sorted_numbers.insert(i+1, unsorted_num)
					break
			elif unsorted_num < sorted_numbers[i]:
				if (i == 0) :
					sorted_numbers.insert(0, unsorted_num)
					break
				elif unsorted_num > sorted_numbers[i-1]:
					sorted_numbers.insert(i-1, unsorted_num)
					break
			elif allow_duplicates:
				sorted_numbers.insert(i, unsorted_num)
				break
	return sorted_numbers

var _animRoot_scene_paths: Array = []
var _animRoot_scene_paths_iter: int = 0
func _append_children_to_array(parent: Node, animRoot: Node, max_iters: int = 0):
	if max_iters > 0: # max_iters over 0 means root scene.
		_animRoot_scene_paths = []
		_animRoot_scene_paths_iter = max_iters
	
	for child in parent.get_children():
		if _animRoot_scene_paths_iter == 0:
			return
		_animRoot_scene_paths_iter -= 1
		
		_animRoot_scene_paths.append(str(animRoot.get_path_to(child)))
		_append_children_to_array(child, animRoot)

func _get_sample_length(sample: AudioStreamSample) -> float:
	return stepify(float(sample.data.size()) / (sample.mix_rate * 4), 0.01)
