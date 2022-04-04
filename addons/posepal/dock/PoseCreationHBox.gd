tool
extends HBoxContainer

signal pose_editing_canceled
signal pose_editing_saved

# This script reference is just for autocompletion.
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

const TEX_IconSave: StreamTexture = preload("res://addons/posepal/assets/icons/icon_save.png")
const TEX_IconNew: StreamTexture = preload("res://addons/posepal/assets/icons/icon_new.png")

enum PoseType {
	NORMAL,  # Animation Pose - Stores property animation keys.
	FILTER,  # Filter Pose - Poses with nodes outside the Filter pose will be ignored.
	TEMPLATE # Base pose used as a template for all poses inside its collection.
}
var current_pose_type: int = PoseType.NORMAL

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
func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	var newPoseButton: Button = $NewPoseButton
	newPoseButton.connect("pressed", self, "_on_NewPoseButton_pressed")
	$CancelPoseButton.connect("pressed", self, "_on_CancelPoseButton_pressed")
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
	match new_mode:
		PoseGenMode.CREATE:
			selected_animation = ''
			newPoseButton.text = "New Pose"
			newPoseButton.icon = TEX_IconNew
			cancelPoseButton.visible = false
			selected_pose_id = -1
			if is_instance_valid(animationPlayer):
				animationPlayer.queue_free()
			var poseCreationColumn: PanelContainer = $"../../TabContainer/PoseLib/VBox/OptionsMargin/OptionsVBox/PoseCreationColumn"
			poseCreationColumn.is_locked = true
			_show_editorSceneTabs()
		PoseGenMode.SAVE:
			newPoseButton.text = "Save Pose"
			newPoseButton.icon = TEX_IconSave
			cancelPoseButton.visible = true
			var poseCreationColumn: PanelContainer = $"../../TabContainer/PoseLib/VBox/OptionsMargin/OptionsVBox/PoseCreationColumn"
			poseCreationColumn.is_locked = false
	posegen_mode = new_mode

func _on_PoseLibrary_updated_reference(reference :String):
	_show_editorSceneTabs()
	self.posegen_mode = PoseGenMode.CREATE
	if is_instance_valid(animationPlayer):
		animationPlayer.queue_free()

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
		_show_editorSceneTabs()
		return
	if posegen_mode == PoseGenMode.CREATE:
		apply_pose(0, PoseType.TEMPLATE)
		owner.load_poseData()
		if !are_parameters_valid():
			print('param invalid')
			return
		edit_pose(-1, PoseType.NORMAL)
		
	elif posegen_mode == PoseGenMode.SAVE:
		var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
		var anim: Animation= animationPlayer.get_animation(currentAnimOptionButton.text)
		
		if anim.get_track_count() == 0:
			print("[posepal] pose empty, can't save.")
			emit_signal("pose_editing_canceled")
			self.posegen_mode = PoseGenMode.CREATE
			return
		
		save_pose(selected_pose_id)
		emit_signal("pose_editing_saved")
		
		# [] Fill all for changes of 1 is overkill. Should replace with a regenerate function in future.
		var pageHBox = $"../../TabContainer/Pallete/HBox/PageHBox"
		if selected_pose_id == -1:
			pageHBox.current_page = pageHBox.get_page_count()-1
		else:
			owner.posePalette.fill_previews()
		self.posegen_mode = PoseGenMode.CREATE

# open pose editor | select pose | 
func edit_pose(pose_id: int, pose_type: int = PoseType.NORMAL):
	var poselib: RES_PoseLibrary = owner.current_poselib
	var pose_name: String = str(pose_id)
	if pose_type == PoseType.FILTER:
		if !poselib.filterData.has(owner.poselib_filter):
			return
		
		pose_name = owner.poselib_filter
	elif pose_type == PoseType.TEMPLATE:
		if !poselib.templateData.has(owner.poselib_template):
			return
		
		pose_name = owner.poselib_template
	elif pose_type == PoseType.NORMAL:
		if (pose_id == -1
		or pose_id > poselib.poseData[owner.poselib_template][owner.poselib_collection].size() -1):
			pose_id = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()
			pose_name = str(pose_id)
		elif poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
			pose_name = poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name']
	current_pose_type = pose_type
			
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
	
#	Check if selected AnimationPlayer is the same as poselib_animplayer,
#	If it is, save it for when the pose is saved/canceled.
	var selected_nodes: Array = editorSelection.get_selected_nodes()
	if owner.poselib_animPlayer in selected_nodes:
		_do_queue_select_poselib_animplayer = true
		
#	Instance a temporary AnimationPlayer and Animation for pose editing.
	if is_instance_valid(animationPlayer):
		animationPlayer.queue_free()
	var newPoseButton: Button = $NewPoseButton
	animationPlayer = AnimationPlayer.new()
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
	anim.length = 0.01
	animationPlayer.advance(0.01)
	animationPlayer.seek(0.01, true)
	
	# If pose exists, load pose.
	if pose_type == PoseType.NORMAL:
		if pose_id < poselib.poseData[owner.poselib_template][owner.poselib_collection].size():
			var err = load_pose(pose_id, PoseType.NORMAL)
			selected_pose_id = pose_id
		else:
#			Templates shouldn't be stored on the poses inside it. They're just applied.
			self.posegen_mode = PoseGenMode.SAVE
	elif pose_type == PoseType.FILTER:
		var err = load_pose(0, PoseType.FILTER)
	else:
		var err = load_pose(0, PoseType.TEMPLATE)

func _on_EditedSceneRoot_tree_exiting():
	if !is_instance_valid(animationPlayer):
		return
	print("[posepal] CRITICAL ERROR - Edited scene changed while pose editor is active. Please cancel changes before changing scenes.")
	animationPlayer.root_node = NodePath('..')#animationPlayer.get_path_to(self)
	animationPlayer.clear_caches()
	animationPlayer.clear_queue()
	
	for anim in animationPlayer.get_animation_list():
		animationPlayer.remove_animation(anim)
	animationPlayer.play("RESET")
	var newPoseButton: Button = $NewPoseButton
	for child in newPoseButton.get_children():
		child.set_process_input(false)
		child.queue_free()

func to_key_value(pose: Dictionary, node_path: String, property: String, f: File):
	var poselib: RES_PoseLibrary = owner.current_poselib
	var editedSceneRoot: Node= get_tree().edited_scene_root
	var poseSceneRoot: Node= editedSceneRoot.get_node(owner.poselib_scene)
	var animNode: Node= poseSceneRoot.get_node_or_null(node_path)
	var value = pose[node_path][property]['val']
	var value_ref = pose[node_path][property]['valr']

	match typeof(animNode.get(property)):
		TYPE_OBJECT:
			if property == 'texture':
				var ref_id: int = poselib.get_id_from_res(value)
				var path: String = poselib.resourceReferences[ref_id][poselib.ReferenceType.PATH]
				if f.file_exists(path):
					match path.get_extension():
						'png','jpg':
							return poselib.resourceReferences_resources[ref_id]
						_:
							return null
		_:
			return value
	return null

func apply_pose(pose_id: int, pose_type: int = -1):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	
	var pose: Dictionary
	if pose_type == -1: pose_type = current_pose_type
	if pose_type == PoseType.NORMAL:
		if owner.poselib_template == '' or owner.poselib_collection == '':
			return
		pose = poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].duplicate()
		pose.erase('_name')
	elif pose_type == PoseType.FILTER:
		pose = poselib.filterData[owner.poselib_filter]
	else:
		if owner.poselib_template == '':
			return
		pose = poselib.templateData[owner.poselib_template]
	
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	
	for node_path in pose.keys():
		var animNode: Node = poseSceneRoot.get_node_or_null(node_path)
		if !is_instance_valid(animNode):
			break
		for property in pose[node_path]:
			var value
			if !pose[node_path][property].has('val'):
				value = poselib.get_res_from_id(pose[node_path][property]['valr'])
			else:
				value = pose[node_path][property]['val']
			animNode.set(property, value)

func load_pose(pose_id: int, pose_type: int= -1):# -> int:
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
	for node_path in pose:
		if node_path == "_name":
			continue
		var animNode: Node = poseSceneRoot.get_node_or_null(node_path)
		if !is_instance_valid(animNode):
			break
		
		for property in pose[node_path]:
			var value
			if pose[node_path][property].has('val'):
				value = pose[node_path][property]['val']
			else:
				if pose[node_path][property].has('valr'):
					value = poselib.get_res_from_id(pose[node_path][property]['valr'])
			
			var tr_property: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_property, str(poseSceneRoot.get_path_to(animNode)) + ':' + property)
			
			var key_value = value
			var transition_out: float = 1.0
			var transition_in: float = 1.0
			if pose[node_path][property].has('out'):
				transition_out = pose[node_path][property]['out']
				
			elif pose_type == PoseType.NORMAL:
				if poselib.templateData[owner.poselib_template].has(node_path):
					if poselib.templateData[owner.poselib_template][node_path].has(property):
						if poselib.templateData[owner.poselib_template][node_path][property].has('out'):
							transition_out = poselib.templateData[owner.poselib_template][node_path][property]['out']
			
			if pose[node_path][property].has('in'):
				transition_in = pose[node_path][property]['in']
				anim.track_insert_key(tr_property, -1.0, key_value, transition_in)
			
			anim.track_insert_key(tr_property, 0.0, key_value, transition_out)
			if pose_type == PoseType.NORMAL or pose_type == PoseType.TEMPLATE:
				if poselib.templateData[owner.poselib_template].has(node_path):
					if poselib.templateData[owner.poselib_template][node_path].has(property):
						if poselib.templateData[owner.poselib_template][node_path][property].has('upmo'):
							anim.value_track_set_update_mode(tr_property,
							  poselib.templateData[owner.poselib_template][node_path][property]['upmo'])
	self.posegen_mode = PoseGenMode.SAVE
	return true # returns true if loading was succesful

func save_pose(pose_id: int, pose_type: int = PoseType.NORMAL):
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
	var is_pose_new: bool = false
	if current_pose_type == PoseType.NORMAL:
		if (pose_id == -1
		or pose_id > poselib.poseData[owner.poselib_template][owner.poselib_collection].size() - 1):
			poselib.poseData[owner.poselib_template][owner.poselib_collection].append({})
			is_pose_new = true
		else:
			if !poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
				poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = {}
			else:
				poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = {'_name':
				  poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name']}
	elif current_pose_type == PoseType.FILTER:
		poselib.filterData[owner.poselib_filter] = {}
	else:
		poselib.templateData[owner.poselib_template] = {}
	
	for i in Anim.get_track_count():
		var track_path: NodePath = Anim.track_get_path(i) # (@@@)/./Sprite:position
		var path_subnames: NodePath = track_path.get_concatenated_subnames() # :position
		var node_path: String = str(track_path).rstrip(str(path_subnames)).rstrip(':') # position
		var node: Node = poseSceneRoot.get_node(node_path)
		
		if node_path == '':
			node_path = '.'
		var key_out: int = Anim.track_find_key(i, Anim.length, false) # Current Key
		var key_in: int = Anim.track_find_key(i, -0.05, false) # Previous Key
		
		if key_out != -1:
			if Anim.track_get_key_time(i, key_out) >= 0.0:
				_save_track_property_to_poseData(i, pose_id, node_path, node, track_path.get_subname(0), key_out, key_in)
	
	owner.save_poseData()
	if is_pose_new:
		owner.emit_signal('pose_created', pose_id)
	
	animationPlayer.remove_animation(currentAnimOptionButton.text)
	animationPlayer.queue_free()
	if _do_queue_select_poselib_animplayer:
		_select_queued_poselib_animplayer()

func are_parameters_valid() -> bool:
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return false
	if (!poselib.poseData.has(owner.poselib_template) or !poselib.templateData.has(owner.poselib_template)
	or  !poselib.filterData.has(owner.poselib_filter)):
		return false
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return false
	return true

func _save_track_property_to_poseData(track_index: int, pose_id: int, node_path: String, node: Node, property: String, key_out: float = 1.0, key_in: float = -1.0):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	var anim: Animation = animationPlayer.get_animation(selected_animation)
	if !is_instance_valid(anim):
		return
		
	if current_pose_type == PoseType.NORMAL:
		if !poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has(node_path):
			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path] = {}
		
		poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property] = {}
		
		if typeof(node.get(property)) != TYPE_OBJECT:
			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
		else:
			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['valr'] = poselib.get_id_from_res(anim.track_get_key_value(track_index, key_out))
		
		poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)
		if key_in != -1.0:
			if anim.track_get_key_time(track_index, key_in) < 0:
				owner.poseData[owner.poselib_template][owner.poselib_collection][pose_id][node_path][property]['in'] = anim.track_get_key_transition(track_index, key_in)
	elif current_pose_type == PoseType.FILTER:
		if !poselib.filterData[owner.poselib_filter].has(node_path):
			poselib.filterData[owner.poselib_filter][node_path] = {}
		poselib.filterData[owner.poselib_filter][node_path][property] = {}
		
		if typeof(node.get(property)) != TYPE_OBJECT:
			poselib.filterData[owner.poselib_filter][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
		else:
			poselib.filterData[owner.poselib_filter][node_path][property]['valr'] = poselib.get_id_from_res(anim.track_get_key_value(track_index, key_out))
		
		poselib.filterData[owner.poselib_filter][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)
		if key_in != -1.0:
			if anim.track_get_key_time(track_index, key_in) < 0:
				poselib.filterData[owner.poselib_filter][node_path][property]['in'] = anim.track_get_key_transition(track_index, key_in)
	else: # TEMPLATE
		if !poselib.templateData[owner.poselib_template].has(node_path):
			poselib.templateData[owner.poselib_template][node_path] = {}
		poselib.templateData[owner.poselib_template][node_path][property] = {}
		
		if typeof(node.get(property)) != TYPE_OBJECT:
			poselib.templateData[owner.poselib_template][node_path][property]['val'] = anim.track_get_key_value(track_index, key_out)
		else:
			poselib.templateData[owner.poselib_template][node_path][property]['valr'] = poselib.get_id_from_res(anim.track_get_key_value(track_index, key_out))
		
		poselib.templateData[owner.poselib_template][node_path][property]['out'] = anim.track_get_key_transition(track_index, key_out)
		poselib.templateData[owner.poselib_template][node_path][property]['upmo'] = anim.value_track_get_update_mode(track_index)



func _hide_editorSceneTabs():
	var sceneTabs: Tabs = owner.pluginInstance.editorSceneTabs 
	sceneTabs.visible = false

func _show_editorSceneTabs():
	var sceneTabs: Tabs = owner.pluginInstance.editorSceneTabs 
	sceneTabs.visible = true

# Godot crashes when edited scene changes while pose is still being edited.
func _on_scene_changed(_sceneRoot: Node):
	posegen_mode = PoseGenMode.CREATE
	if _sceneRoot == owner:
		return
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	var newPoseButton: Button = $NewPoseButton
	
	for child in newPoseButton.get_children():
		child.queue_free()
	return

func _on_CancelPoseButton_pressed():
	emit_signal("pose_editing_canceled")
	self.posegen_mode = PoseGenMode.CREATE
	
	if !_do_queue_select_poselib_animplayer:
		return
	_select_queued_poselib_animplayer()

func _select_queued_poselib_animplayer():
	_do_queue_select_poselib_animplayer = false
	if !is_instance_valid(owner.poselib_animPlayer):
		return
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	
	editorSelection.add_node(owner.poselib_animPlayer)
