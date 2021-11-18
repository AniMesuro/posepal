tool
extends VBoxContainer

signal pose_editing_canceled

# This script reference is just for autocompletion.
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

const TEX_IconSave: StreamTexture = preload("res://addons/posepal/assets/icons/icon_save.png")
const TEX_IconNew: StreamTexture = preload("res://addons/posepal/assets/icons/icon_new.png")
#const SCN_newPosePopup :PackedScene= preload("res://addons/posepal/new_pose_popup/NewPosePopup.tscn")

enum PoseType {
	NORMAL,  # Animation Pose - Stores property animation keys.
	FILTER,  # Filter Pose - Poses with nodes outside the Filter pose will be ignored.
	TEMPLATE # Base pose used as a template for all poses inside its collection.
}
var current_pose_type: int= PoseType.NORMAL

enum PoseGenMode {
	CREATE,
	EDIT,
	SAVE
}
var posegen_mode: int = PoseGenMode.CREATE setget _set_posegen_mode

var _do_queue_select_poselib_animplayer: bool = false

var animationPlayer: AnimationPlayer
var selected_animation: String = ''
var selected_pose_id: int = -1
#var anim: Animation
func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	var newPoseButton: Button = $NewPoseButton
	newPoseButton.connect("pressed", self, "_on_NewPoseButton_pressed")
	owner.connect('updated_reference', self, '_on_PoseLibrary_updated_reference')
	var pluginInstance: EditorPlugin = owner.pluginInstance
	pluginInstance.connect("scene_changed", self, "_on_scene_changed")
	$CancelPoseButton.visible = false

func _set_posegen_mode(new_mode :int):
	var newPoseButton: Button = $NewPoseButton
	var cancelPoseButton: Button = $CancelPoseButton
	if posegen_mode == new_mode:
		match new_mode:
			PoseGenMode.CREATE:
				if cancelPoseButton.visible == false:
					return
			PoseGenMode.SAVE:
				if cancelPoseButton.visible == true:
					return
	print('posegen is ',new_mode)
	match new_mode:
		PoseGenMode.CREATE:
			selected_animation = ''
			newPoseButton.text = "New Pose"
			newPoseButton.icon = TEX_IconNew
			cancelPoseButton.visible = false
			cancelPoseButton.disconnect("pressed", self, "_on_CancelPoseButton_pressed")
			selected_pose_id = -1
			if is_instance_valid(animationPlayer):
				animationPlayer.queue_free()
		PoseGenMode.SAVE:
			newPoseButton.text = "Save Pose"
			newPoseButton.icon = TEX_IconSave
			cancelPoseButton.visible = true
			cancelPoseButton.connect("pressed", self, "_on_CancelPoseButton_pressed")
	posegen_mode = new_mode

# owner_reference (reference)
# DESELECT_ANIM	

func _on_PoseLibrary_updated_reference(reference :String):
	self.posegen_mode = PoseGenMode.CREATE
	if is_instance_valid(animationPlayer):
		animationPlayer.queue_free()
#	anim = null
#	if posegen_mode == PoseGenMode.CREATE:
#		return
#	if owner.poselib_scene == "":
#		posegen_mode = PoseGenMode.CREATE
#		return
#	if !owner.poseData.has('collections'):
#		posegen_mode = PoseGenMode.CREATE
#		return
#	if !owner.poseData.has(owner.poselib_template):
#		posegen_mode = PoseGenMode.CREATE
#		return
#	if !owner.poseData.has(owner.poselib_collection):
#		posegen_mode = PoseGenMode.CREATE
#		return
	

var newPosePopup :Control
func _on_NewPoseButton_pressed():
	if !is_instance_valid(get_tree().edited_scene_root):
		owner.issue_warning('edited_scene_invalid')
	if owner.poselib_scene == '':
		owner.issue_warning('lacking_parameters')
	if owner.poselib_template == '':
		owner.issue_warning('lacking_parameters')
	if owner.poselib_collection == '':
		owner.issue_warning('lacking_parameters')
	
	
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	if posegen_mode == PoseGenMode.CREATE:
		apply_pose(0, PoseType.TEMPLATE)
		owner.load_poseData()
		print('new_pose')
		#Check if all parameters are valid
		if !are_parameters_valid():
			print('param invalid')
			return
#		var available_id: int = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()
#		for i in 50:
#			if str(available_id) in poselib.poseData[owner.poselib_template][owner.poselib_collection]:
#				available_id += 1
#				continue
#			break
#		print('available id = ',available_id)
#		load_pose(owner.poselib_template, PoseType.FILTER)
		edit_pose(-1, PoseType.NORMAL) # Pose data are arrays so -1 will give you last value.
	#	load_node_selection()
		
		
	elif posegen_mode == PoseGenMode.SAVE:
		print('save 83')
		
		save_pose(selected_pose_id)
		self.posegen_mode = PoseGenMode.CREATE
		_show_editorSceneTabs()
#		owner.save_poseData()
#		owner.load_poseData()
		owner.posePalette.fill_previews()
##	#	#	#	#	#	#	#	#	#	#	#	#


# open pose editor | select pose | 
func edit_pose(pose_id: int, pose_type: int = PoseType.NORMAL):
	var poselib: RES_PoseLibrary = owner.current_poselib
	var pose_name: String = str(pose_id)
	if pose_type == PoseType.FILTER:
		if !poselib.filterData.has(owner.poselib_filter):
			return
#		pose_id is ignored if pose is filter pose.
		pose_name = owner.poselib_filter
	elif pose_type == PoseType.TEMPLATE:
		if !poselib.templateData.has(owner.poselib_template):
			return
		pose_name = owner.poselib_template
		
#		if owner.poselib_filter != 'none':
#			if poselib.filterData[owner.poselib_filter].has('_name'):
#				pose_name = poselib.filterData[owner.poselib_filter]['_name']
	elif pose_type == PoseType.NORMAL:
		if (pose_id == -1
		or pose_id > poselib.poseData[owner.poselib_template][owner.poselib_collection].size() -1):
			pose_id = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()
			pose_name = str(pose_id)
			
		
		elif poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
			pose_name = poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name']
	current_pose_type = pose_type
	
	
	
#	Reference Editor Nodes
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	if !is_instance_valid(currentTimeLineEdit):
		owner.pluginInstance._get_editor_references()
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	if !editedSceneRoot.is_connected("tree_exiting", self, "_on_EditedSceneRoot_tree_exiting"):
		editedSceneRoot.connect("tree_exiting", self, "_on_EditedSceneRoot_tree_exiting")
#		if editedSceneRoot.is_connected("tree_exiting", self, "_on_EditedSceneRoot_tree_exiting"):
#			print('edited scene is connected tree')
	
#	Check if selected AnimationPlayer is the same as poselib_animplayer,
#	If it is, save it for when the pose is saved/canceled.
	var selected_nodes: Array = editorSelection.get_selected_nodes()
	print(owner.poselib_animPlayer, selected_nodes)
	if owner.poselib_animPlayer in selected_nodes:
		print(owner.poselib_animPlayer,' is queued to be selected')
		_do_queue_select_poselib_animplayer = true
		
#	Instance a temporary AnimationPlayer and Animation for pose editing.
	if is_instance_valid(animationPlayer):
		animationPlayer.queue_free()
	var newPoseButton: Button = $NewPoseButton
	animationPlayer = AnimationPlayer.new()#owner.get_node("AnimationPlayer")
	animationPlayer.name = "PoseAnimationPlayer"
	newPoseButton.add_child(animationPlayer)
	for anim in animationPlayer.get_animation_list():
		animationPlayer.remove_animation(anim)
	var anim: Animation = Animation.new()
	
#	Select animation for editing.
	animationPlayer.root_node = get_path_to(poseSceneRoot)
	animationPlayer.add_animation(pose_name, anim)
	animationPlayer.assigned_animation = pose_name
	animationPlayer.root_node = animationPlayer.get_path_to(poseSceneRoot)
	editorSelection.clear()
	editorSelection.add_node(animationPlayer)
	
	
	_hide_editorSceneTabs()
	selected_animation = pose_name
#	Should move time cursor to 0.0 but doesn't work.
	animationPlayer.advance(0.1)
	animationPlayer.seek(0.1, true)
	
	print('anim position =',animationPlayer.current_animation_position)
#	anim.
#		print("end current_time =",currentTimeLineEdit.get_parent().value)
#		currentTimeLineEdit.get_parent().value = 0.0
#		currentTimeLineEdit.get_parent().emit_signal("value_changed", 0.0)
#		currentTimeLineEdit.get_parent().apply()
#		currentTimeLineEdit.text = "0.0"
#		currentTimeLineEdit.emit_signal("text_changed", "0.0")
#		print("end current_time =",currentTimeLineEdit.get_parent().value)
#		currentAnimOptionButton.connect(
	
	# If pose exists, load pose.
	if pose_type == PoseType.NORMAL:
#		apply_pose(0, PoseType.TEMPLATE)
		if pose_id < poselib.poseData[owner.poselib_template][owner.poselib_collection].size():
			var err = load_pose(pose_id, PoseType.NORMAL)
#			if !err: posegen_mode = PoseGenMode.CREATE; print('loading pose failed')
			selected_pose_id = pose_id
		else:
#			Templates shouldn't be stored on the poses inside it. They're just applied.

#			load_pose(0, PoseType.TEMPLATE)
#			selected_pose_id = pose_id
			self.posegen_mode = PoseGenMode.SAVE
	elif pose_type == PoseType.FILTER:
		var err = load_pose(0, PoseType.FILTER)
#		if !err: posegen_mode = PoseGenMode.CREATE; print('loading pose failed')
	else:
		var err = load_pose(0, PoseType.TEMPLATE)
#		if !err: posegen_mode = PoseGenMode.CREATE; print('loading pose failed')

func _on_EditedSceneRoot_tree_exiting():
##	print('edited scene is exiting tree: ',get_tree().edited_scene_root)
	if !is_instance_valid(animationPlayer):
		return
	print("[PosePal] CRITICAL ERROR - Edited scene changed while pose editor is active. Please cancel changes before changing scenes.")
	animationPlayer.root_node = NodePath('..')#animationPlayer.get_path_to(self)
	animationPlayer.clear_caches()
	animationPlayer.clear_queue()
#	var editorInterface :EditorInterface= owner.pluginInstance.get_editor_interface()
#	var editorSelection :EditorSelection= editorInterface.get_selection()
#	animationPlayer.root_node = animationPlayer.get_path_to(self)#NodePath('..')
	for anim in animationPlayer.get_animation_list():
		animationPlayer.remove_animation(anim)
	animationPlayer.play("RESET")
	var newPoseButton: Button = $NewPoseButton
	for child in newPoseButton.get_children():
		child.set_process_input(false)
		child.queue_free()
#		print(child,'  has signals: ',child,get_signal_list())
	
#	editorSelection.clear()
#	var poselibraryAnimPlayer = owner.get_node('AnimationPlayer')
#	print('poselib animaplayer = ',poselibraryAnimPlayer)
#	editorSelection.add_node(poselibraryAnimPlayer)
#	animationPlayer.queue_free()
##		anim = null
#	posegen_mode = PoseGenMode.CREATE

# poseData_
#func to_key_value(pose: Dictionary, node_path: String, property: String):
#	var editedSceneRoot: Node= get_tree().edited_scene_root
#	var poseSceneRoot: Node= editedSceneRoot.get_node(owner.poselib_scene)
#	var animNode: Node= poseSceneRoot.get_node_or_null(node_path)
##	var pose: Dictionary = owner.poseData[owner.poselib_template][owner.poselib_collection][pose_id]
#	var value = pose[node_path][property]['val']#owner.poseData[owner.poselib_template][owner.poselib_collection][pose_id]
#
##	var key_value
#	match typeof(animNode.get(property)):
#		TYPE_VECTOR2:
#			return Vector2(
#				value[0],
#				value[1]
#				)
#		TYPE_OBJECT:
#			if property == 'texture':
#				var f: File = File.new()
#				if f.file_exists(value):
#					match value.get_extension():
#						'png','jpg':
#							return load(value)
#						_:
#							return null
#		_:
#			return value
#	return null

func apply_pose(pose_id: int, pose_type: int = -1):
	print('applying pose')
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	
	var pose: Dictionary
	if pose_type == -1: pose_type = current_pose_type
	if pose_type == PoseType.NORMAL:
		print('alllll poses = ',poselib.poseData[owner.poselib_template][owner.poselib_collection])
		pose = poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]
	elif pose_type == PoseType.FILTER:
		pose = poselib.filterData[owner.poselib_filter]
	else:
		pose = poselib.templateData[owner.poselib_template]
	
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
#		var animRoot: Node = animationPlayer.root_node
	for node_path in pose.keys():
		if node_path == "_name":
			continue
		var animNode: Node = poseSceneRoot.get_node_or_null(node_path)
		if !is_instance_valid(animNode):
			break
		for property in pose[node_path]:
			var value
			if !pose[node_path][property].has('val'):
				break
			value = pose[node_path][property]['val']
			animNode.set(property, value)
			

# Loads the pose from the Poselib
func load_pose(pose_id: int, pose_type: int= -1):# -> int:
	print('loading pose')
	if !(is_instance_valid(animationPlayer)):
		return
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	
	var pose: Dictionary
	if pose_type == -1: pose_type = current_pose_type
	if pose_type == PoseType.NORMAL:
		pose = poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]
	elif pose_type == PoseType.FILTER:
		pose = poselib.filterData[owner.poselib_filter]
	else:
		pose = poselib.templateData[owner.poselib_template]
	
	var anim: Animation = animationPlayer.get_animation(selected_animation)
	if !is_instance_valid(anim):
		return
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
#		var animRoot: Node = animationPlayer.root_node
	for node_path in pose:
		if node_path == "_name":
			continue
		var animNode: Node = poseSceneRoot.get_node_or_null(node_path)
		if !is_instance_valid(animNode):
			break
		for property in pose[node_path]:
			var value
			if !pose[node_path][property].has('val'):
				break
			value = pose[node_path][property]['val']
			
			var tr_property: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_property, str(poseSceneRoot.get_path_to(animNode)) + ':' + property)
			
			var key_value = value#to_key_value(pose, node_path, property)
#			match typeof(animNode.get(property)):
#				TYPE_VECTOR2:
#					key_value = Vector2(
#						value[0],
#						value[1]
#						)
#				TYPE_OBJECT:
#					if property != 'texture':
#						break
#					var f: File = File.new()
#					if f.file_exists(value):
#						match value.get_extension():
#							'png','jpg':
#								key_value = load(value)
#							_:
#								break
#				_:
#					key_value = value
			
			
			var transition_out: float = 1.0
			var transition_in: float = 1.0
			if pose[node_path][property].has('out'):
				transition_out = pose[node_path][property]['out']
			if pose[node_path][property].has('in'):
				transition_in = pose[node_path][property]['in']
				anim.track_insert_key(tr_property, -1.0, key_value, transition_in)
			
			
			anim.track_insert_key(tr_property, 0.0, key_value, transition_out)
	
	self.posegen_mode = PoseGenMode.SAVE
	return true # returns true if loading was succesful

func save_pose(pose_id: int, pose_type: int = PoseType.NORMAL):
	print('saving pose ',pose_type)
	if !is_instance_valid(animationPlayer):
		return
	var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	if !is_instance_valid(currentAnimOptionButton):
		owner.pluginInstance._get_editor_references()
	var Anim :Animation= animationPlayer.get_animation(currentAnimOptionButton.text)
	if !is_instance_valid(Anim):
		return
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	if !is_instance_valid(poseSceneRoot):
		return
	
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	
	# Create pose if pose doesn't exist at pose data.
#	var is_empty: bool = false
	print('pose type =',pose_type)
	if current_pose_type == PoseType.NORMAL:
		if pose_id > poselib.poseData[owner.poselib_template][owner.poselib_collection].size() - 1:
			poselib.poseData[owner.poselib_template][owner.poselib_collection].append({})
#			is_empty = true
		else:
			if !poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
				poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = {}
			else:
				poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = {'_name':
					poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name']}
	elif current_pose_type == PoseType.FILTER:
		poselib.filterData[owner.poselib_filter] = {}
#		if !owner.poselib_filter in poselib.filterData:
		print(owner.poselib_filter,' is empty')
#			poselib.filterData[owner.poselib_filter] = {}
#			is_empty = true
#		else:
#			poselib.filterData[owner.poselib_filter] = {}
	else:
		poselib.templateData[owner.poselib_template] = {}
		print(owner.poselib_template,' is empty')
		
#	poselib = null
	
	
	for i in Anim.get_track_count():
		var track_path: NodePath = Anim.track_get_path(i) # (@@@)/./Sprite:position
		var path_subnames: NodePath = track_path.get_concatenated_subnames() # :position
		var node_path: String = str(track_path).rstrip(str(path_subnames)).rstrip(':') # position
		
		if node_path == '':
			node_path = '.'
		
#		var key_out: int = Anim.track_get_key_count(i)-1
		var key_out: int = Anim.track_find_key(i, Anim.length, false) # Current Key
		var key_in: int = Anim.track_find_key(i, -0.05, false) # Previous Key
#		var last_key: int = Anim.track_find_key(i, Anim.length, false)
#		print('last key found ', last_key, Anim.track_get_key_time(i, last_key))
#		var key_in :int= Anim.track_find_key(i, -60.0, false) # Previous Key
		
		
		# -1 didn't find
		if key_out != -1:
			if Anim.track_get_key_time(i, key_out) >= 0.0:
				_save_track_property_to_poseData(i, pose_id, node_path, track_path.get_subname(0), key_out, key_in)
#		owner.poseData[owner.poselib_template][owner.poselib_collection][currentAnimOptionButton.text][node_path][property_path.get_subname(0)]['val'] = Anim.track_get_key_value(i, key_out)
	
#	print('PoseData = ', poselib.poseData)
#	print('owner PoseData = ', owner.current_poselib.poseData)
	owner.save_poseData()
	animationPlayer.remove_animation(currentAnimOptionButton.text)
	animationPlayer.queue_free()
	
	if _do_queue_select_poselib_animplayer:
		_select_queued_poselib_animplayer()
#	anim = null
	
#	animationPlayer.stop(true)
#	animationPlayer.clear_caches()
#	animationPlayer.clear_queue()
#	print('all anims =',animationPlayer.get_animation_list())
#		print('track ',i,' = ',property_path,'\n',path_subnames,'\n',node_path)
#		print('save track ', i,' ', track_path,'\nsave prop ',i,' ', property_path)

func _save_track_property_to_poseData(track_index: int, pose_id: int, node_path: String, property: String, key_out: float = 1.0, key_in: float = -1.0):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	var anim: Animation = animationPlayer.get_animation(selected_animation)
	if !is_instance_valid(anim):
		return
	if current_pose_type == PoseType.NORMAL:
#		if pose_id > poselib.poseData[owner.poselib_template][owner.poselib_collection].size() - 1:
#			poselib.poseData[owner.poselib_template][owner.poselib_collection].append({})
#			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = {}
		if !poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has(node_path):
			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path] = {}
		
		poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property] = {}

		poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
		poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)
		if key_in != -1.0:
			if anim.track_get_key_time(track_index, key_in) < 0:
				owner.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['in'] = anim.track_get_key_transition(track_index, key_in)
	elif current_pose_type == PoseType.FILTER:
#		if !poselib.filterData.has(owner.poselib_filter):
#			poselib.filterData[owner.poselib_filter] = {}
		if !poselib.filterData[owner.poselib_filter].has(node_path):
			poselib.filterData[owner.poselib_filter][node_path] = {}
		poselib.filterData[owner.poselib_filter][node_path][property] = {}
		
		poselib.filterData[owner.poselib_filter][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
		poselib.filterData[owner.poselib_filter][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)
		if key_in != -1.0:
			if anim.track_get_key_time(track_index, key_in) < 0:
				poselib.filterData[owner.poselib_filter][node_path][property]['in'] = anim.track_get_key_transition(track_index, key_in)
	else:
		if !poselib.templateData[owner.poselib_template].has(node_path):
			poselib.templateData[owner.poselib_template][node_path] = {}
		poselib.templateData[owner.poselib_template][node_path][property] = {}
		
		poselib.templateData[owner.poselib_template][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
#		poselib.templateData[owner.poselib_template][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)

func are_parameters_valid() -> bool:
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return false
	
#	if !owner.poseData.has('collections'):
#		return false
	if !poselib.poseData.has(owner.poselib_template):
		return false
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return false
	if !poselib.filterData.has(owner.poselib_filter):
		return false
	if !poselib.templateData.has(owner.poselib_template):
		return false
	return true

func _hide_editorSceneTabs():
	var sceneTabs: Tabs = owner.pluginInstance.editorSceneTabs 
	print(sceneTabs)
#	if !is_instance_valid(sceneTabs):
#		owner.pluginInstance._get_editor_references()
#		sceneTabs = owner.pluginInstance.editorSceneTabs
	sceneTabs.visible = false
#		return
#	if !is_instance_valid(sceneTabs):
#	print("[PosePal] Couldn't hide Scene Tabs. Please do not change scene while editing a pose because it can crash Godot.")

func _show_editorSceneTabs():
	var sceneTabs: Tabs = owner.pluginInstance.editorSceneTabs 
#	print(sceneTabs)
#	if !is_instance_valid(sceneTabs):
#		owner.pluginInstance._get_editor_references()
#		sceneTabs = owner.pluginInstance.editorSceneTabs
	sceneTabs.visible = true
#		return
#	print("[PosePal] Couldn't show Scene Tabs. Try disabling and re-enabling PosePal.")

# Godot crashes when edited scene changes while pose is still being edited.
func _on_scene_changed(_sceneRoot: Node):
	#return
	posegen_mode = PoseGenMode.CREATE
	if _sceneRoot == owner:
		return
#	if !is_instance_valid(owner.pluginInstance):
#		owner.pluginInstance = owner._get_pluginInstance()
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	
#	print('animpl ',animationPlayer)
	var newPoseButton: Button = $NewPoseButton
	for child in newPoseButton.get_children():
		child.queue_free()
	return
	if is_instance_valid(animationPlayer):
		editorSelection.clear()
#		return
#		var _animPlayer: AnimationPlayer= AnimationPlayer.new()
#		add_child(_animPlayer)
#		editorSelection.add_node(_animPlayer)
#		animationPlayer.root_node = NodePath('.')
#		animationPlayer.clear_caches()
#		animationPlayer.root_node = animationPlayer.get_path_to(self)
#		for anim in animationPlayer.get_animation_list():
#			animationPlayer.remove_animation(anim)
#		animationPlayer.add_animation('NULL', Animation.new())
#		animationPlayer.assigned_animation = 'NULL'
#		return
#		yield(get_tree(),"idle_frame")
#		yield(get_tree(),"idle_frame")
#		yield(get_tree(),"idle_frame")
		print('waiting for 5sec to delete animpl')
		yield(get_tree().create_timer(5.0), "timeout")
		print('deleting animpl')
#		for child in get_children()
#		animationPlayer.queue_free()
#		animationPlayer.call_defered("queue_free")
#	anim = null


func _on_CancelPoseButton_pressed():
	print('canceling')
	emit_signal( "pose_editing_canceled")
	self.posegen_mode = PoseGenMode.CREATE
	if !_do_queue_select_poselib_animplayer:
		return
	_select_queued_poselib_animplayer()
	_show_editorSceneTabs()

func _select_queued_poselib_animplayer():
	_do_queue_select_poselib_animplayer = false
	if !is_instance_valid(owner.poselib_animPlayer):
		return
	print('last animplayer being selected')
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	
	editorSelection.add_node(owner.poselib_animPlayer)
