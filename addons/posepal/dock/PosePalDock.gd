tool
extends Control

# posepal Dock

signal updated_reference (reference_name)
signal pose_selected (pose_id)

signal warning_issued (warning_message)
signal warning_fixed (warning_message)

signal issued_forced_selection
signal pose_created (pose_id)

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")
const RES_PosePalSettings: GDScript = preload("res://addons/posepal/PosePalSettings.gd")

const PolygonDataProperties: PoolStringArray = PoolStringArray(['polygon', 'polygons', 'uv', 'skeleton'])

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorControl: Control setget ,_get_editorControl

var poselib_scene: String = "" # Nodepath to a scene that holds a Poselib.
var poselib_filter: String = "" # Pose template and Node filter.
var poselib_template: String = "" # Stores subcollections and template pose data.
var poselib_collection: String = "" # Stores pose data.
var poselib_animPlayer: AnimationPlayer # AnimationPlayer from edited scene to make changes to.

var optionsData: Dictionary = {
	# PREVIEW
	'ignore_scene_pose': false,
	'show_bones': false,
	# KEYING
	'key_template': false,
	'dont_key_duplicate': false,
}

var poseFile_path: String = ""
#var poseData: Dictionary = {}

var queuedPoseData: Dictionary = {}
var queued_key_time: float = -1.0

var settings: RES_PosePalSettings setget ,_get_settings
var currentPoselib: RES_PoseLibrary
var wf_current_poselib: WeakRef

var warningIcon :TextureRect
var posePalette: GridContainer setget ,_get_posePalette
var poseCreationHBox: HBoxContainer setget ,_get_poseCreationHBox
func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		return
	warningIcon = $"VSplit/ExtraHBox/WarningIcon"
	poseCreationHBox = $"VSplit/ExtraHBox/PoseCreationHBox"
	editorControl = pluginInstance.editorControl
	
	# Clear stray instances of invalid docks.
	var _dock_group: String = "plugindock posepal"
	for dock in get_tree().get_nodes_in_group(_dock_group):
		dock.queue_free()
		print("posepal cleansed invalid dock.")
	add_to_group(_dock_group)

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	connect("pose_selected", self, "_on_pose_selected")
#	connect("pose_created", self, "_on_pose_created")
	pluginInstance.connect("scene_changed", self, "_on_scene_changed")
	settings = self.pluginInstance.settings
	

func get_relevant_children() -> Array:
	var editedSceneRoot = get_tree().edited_scene_root
#	var edited_scene_tree :Array= []
	
#	var current_child: Node = editedSceneRoot
#	while current_child.get_child_count() != 0:
##		current_child = current_child
#		edited_scene_tree.append(current_child)
#
	# For each child and its 5 children layers, reference itself to the edited_scene_tree Array
	# Hacky but provides a nesting limit.
#	for child in editedSceneRoot.get_children():
#		edited_scene_tree.append(child)
#
#		for child_a in child.get_children():
#			edited_scene_tree.append(child_a)
#
#			for child_b in child_a.get_children():
#				edited_scene_tree.append(child_b)
#
#				for child_c in child_b.get_children():
#					edited_scene_tree.append(child_c)
#
#					for child_d in child_c.get_children():
#						edited_scene_tree.append(child_d)
#
#						for child_e in child_d.get_children():
#							edited_scene_tree.append(child_e)
#	return edited_scene_tree
#	_add_children_to_scene_tree()
	_select_children_as_array(editedSceneRoot, true, 300)
	return _edited_scene_nodes



func fix_warning(warning :String):
	emit_signal("warning_fixed", warning)
	
func issue_warning(warning :String):
	emit_signal("warning_issued", warning)

func load_poseData(override_path: String = "") -> int:
	if override_path == '' and poselib_scene == "":
		currentPoselib = null
		return FAILED
	elif override_path != '':
		poseFile_path = override_path
	
#	If the poselib is created at the first time, it will only save to file
#	When the first pose is saved.
	var sceneNode: Node = get_tree().edited_scene_root.get_node(poselib_scene)

	var f: File = File.new()
	if !f.file_exists(poseFile_path):
		poseFile_path = ''
		if !is_instance_valid(currentPoselib):
			currentPoselib = RES_PoseLibrary.new()
#			Shoudn't be necessary but it somehow still references values from previous poselibs.
			currentPoselib.clear()
		return OK
	currentPoselib = load(poseFile_path)
	currentPoselib.setup(self.pluginInstance, self)
	var err: int = currentPoselib.prepare_loading_resourceReferences()
#	var err: int = currentPoselib.prepare_loading_resourceReferences()
	currentPoselib.owner_filepath = sceneNode.filename
	
	if override_path !='':
		sceneNode.set_meta('_plPoseLib_poseFile', poseFile_path)
	return err

func save_poseData(override_path: String = ""):
	var selectedScene: Node = get_tree().edited_scene_root.get_node_or_null(poselib_scene)
	if !is_instance_valid(selectedScene):
		return
	var settings: Resource = self.pluginInstance.settings
	
	var f: File = File.new()
	var is_poseFile_valid: bool = false
	
	if (override_path  == '') && selectedScene.has_meta('_plPoseLib_poseFile'):
		var scene_posefile: String = selectedScene.get_meta('_plPoseLib_poseFile')
		if f.file_exists(scene_posefile):
			var filename_pieces: PoolStringArray = scene_posefile.get_file().split(".", false, 2)
			var user_extension: String = settings.PoselibExtensions.keys()[settings.poselib_extension]
			if filename_pieces[1] == "poselib":
				if filename_pieces[2] == user_extension:
					poseFile_path = scene_posefile
					is_poseFile_valid = true
				else:
					poseFile_path = "res://addons/posepal/.poselibs/"+filename_pieces[0]+'.'+filename_pieces[1]+'.'+user_extension
					is_poseFile_valid = true
					selectedScene.set_meta('_plPoseLib_poseFile', poseFile_path)
	elif override_path != '':
		poseFile_path = override_path
		is_poseFile_valid = true
		selectedScene.set_meta('_plPoseLib_poseFile', poseFile_path)
	
	# Reference FilePath to scene's metadata.
	if !is_poseFile_valid:
		var available_path: String = "#"
		var user_extension = settings.PoselibExtensions.keys()[settings.poselib_extension]
		var d: Directory = Directory.new()
		
#		if !d.dir_exists("res://addons/posepal/.poselibs/"):
#			d.make_dir("res://addons/posepal/.poselibs/")
		var scene_dir = selectedScene.filename.get_base_dir()+'/'
		for i in 100:
#			available_path = "res://addons/posepal/.poselibs/" + selectedScene.name+"_"+str(i) + ".poselib." + user_extension
			
			available_path = scene_dir + selectedScene.name+"_"+str(i) + ".poselib." + user_extension
			if f.file_exists(available_path):
				continue
			selectedScene.set_meta('_plPoseLib_poseFile', available_path)
			poseFile_path = available_path
			break
			
		if available_path == '#':
			return
	
	if is_instance_valid(currentPoselib):
		currentPoselib.owner_filepath = selectedScene.filename
		currentPoselib.prepare_saving_resourceReferences()
		var err: int = ResourceSaver.save(poseFile_path, currentPoselib)
		currentPoselib.prepare_loading_resourceReferences()
		if err != OK:
			print('[posepal] saving didnt succeed, error ',err)
		else:
			pass
			
	if override_path != '':
		# if override, select poselib.
		var sceneSelectButton: MenuButton = $"VSplit/TabContainer/PoseLib/VBox/ParametersVBox/SceneHBox/MenuButton"
		load_poseData()
		sceneSelectButton.select_poselib()

# Attempt to, not always succeed. Getting the AnimationPlayer directly in the TimelineEditor is impossible.
func get_selected_animationPlayer() -> AnimationPlayer:
	self.pluginInstance._get_editor_references()
	
	# PoseAnimationPlayer should always prioritized.
	var currentAnimOptionButton: OptionButton = pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var newPoseButton: Button = self.poseCreationHBox.get_node("NewPoseButton")
	var poseButton_children: Array = newPoseButton.get_children()
	if poseButton_children.size() > 0:
		var animPlayer: AnimationPlayer = newPoseButton.get_children()[0]
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			return animPlayer
		
	var editorInterface: EditorInterface = pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	for selectedNode in editorSelection.get_selected_nodes():
		if selectedNode.get_class() != 'AnimationPlayer':
			continue
		var animPlayer: AnimationPlayer = selectedNode
		if currentAnimOptionButton.text == '':
			return null
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			return animPlayer
			
	if is_instance_valid(poselib_animPlayer):
		if poselib_animPlayer.assigned_animation == currentAnimOptionButton.text:
			return poselib_animPlayer

	return null

func get_default_update_mode(property: String, value = null) -> int:
	if (value is bool) or (value is String) or (value is Object):
		return Animation.UPDATE_DISCRETE
	elif value == null:
		match property: 'texture', 'flip_h', 'flip_v', 'visible', 'animation':
			return Animation.UPDATE_DISCRETE
				
	match property:
		'offset', 'frame', 'z_index':
			return Animation.UPDATE_DISCRETE
	return Animation.UPDATE_CONTINUOUS


var _edited_scene_nodes: Array = []
var _select_children_as_array_iter: int = 0
func _select_children_as_array(parent: Node, is_root: bool = false, max_iters: int = 0):
	if is_root:
		_edited_scene_nodes = []
		_select_children_as_array_iter = max_iters
		
	for child in parent.get_children():
		if _select_children_as_array_iter == 0:
			return
		_select_children_as_array_iter -=1
		
		_edited_scene_nodes.append(child)
		_select_children_as_array(child)

func _on_scene_changed(_sceneRoot :Node): #Edited Scene Root
	fix_warning('*')
	poselib_scene = ""
	poselib_template = ""
	poselib_filter = ""
	poselib_collection = ""
	poselib_animPlayer = null
	currentPoselib = null
	emit_signal("updated_reference", "poselib_scene")
	
	posePalette = self.posePalette#$"VSplit/TabContainer/Palette/GridContainer"
	if is_instance_valid(posePalette):
		posePalette.fill_previews()
		

func _get_posePalette():
	posePalette = $"VSplit/TabContainer/Pallete/ScrollContainer/GridContainer"
	return posePalette
	

func _get_pluginInstance() -> EditorPlugin:
	if is_instance_valid(pluginInstance):
		return pluginInstance
	for node in get_tree().get_nodes_in_group("plugin posepal"):
		# queue_free()
		if node is EditorPlugin:
			pluginInstance = node
			return node
	return null

func _get_poseCreationHBox() -> HBoxContainer:
	poseCreationHBox = $"VSplit/ExtraHBox/PoseCreationHBox"
	return poseCreationHBox

func _get_editorControl() -> Control:
	if !is_instance_valid(self.pluginInstance):
		return null
	return self.pluginInstance.get_editor_interface().get_base_control()

func _get_settings():
	return self.pluginInstance.settings

func _key_queued_pose(final_pose: Dictionary):
	if queuedPoseData.size() == 0:
		return
	if !is_instance_valid(poselib_animPlayer):
		issue_warning('animplayer_invalid')
		return
	if !is_instance_valid(self.pluginInstance.animationPlayerEditor):
		pluginInstance._get_editor_references()
	if !poselib_animPlayer.has_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text):
		return
		
	var anim :Animation= poselib_animPlayer.get_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var animRoot :Node= poselib_animPlayer.get_node(poselib_animPlayer.root_node)
	var poseRoot: Node = get_tree().edited_scene_root.get_node(poselib_scene)
	
#	print('finalpose ',final_pose)
	
	for np_id in queuedPoseData.keys():
		var nodepath: String = currentPoselib.get_nodepath_from_id(np_id)
		var node: Node = poseRoot.get_node(nodepath)
		for property in queuedPoseData[np_id].keys():
			var track_path: String = str(animRoot.get_path_to(node))+':'+property
			var tr: int = anim.find_track(track_path)
			if tr == -1:
				continue
			if !final_pose.has(np_id):
				continue
			var _can_continue: bool = false
			if optionsData.dont_key_duplicate:
				for prop in final_pose[np_id].keys():
					if prop != property:
						continue
					if final_pose[np_id][prop].has('val'):
						if queuedPoseData[np_id][property] == final_pose[np_id][prop]['val']:#final_pose[np_id][property]['val']:
							_can_continue = true
							break
					elif final_pose[np_id][prop].has('valr'):
						if queuedPoseData[np_id][property] == currentPoselib.get_res_from_id(final_pose[np_id][prop]['valr']):#final_pose[np_id][property]['val']:
							_can_continue = true
							break
			if _can_continue:
				continue
			anim.track_insert_key(tr, queued_key_time, queuedPoseData[np_id][property])
	
	var optionKeyingVBox: VBoxContainer = $"VSplit/TabContainer/PoseLib/VBox/OptionsMargin/OptionsVBox/KeyingVBox"
	optionKeyingVBox.is_pose_queued = false

func _on_pose_selected(pose_id :int):
	key_pose(pose_id)

var _debug_pose_broken_paths_num: int = 0
func key_pose(pose_id: int):
	if !is_instance_valid(poselib_animPlayer):
		issue_warning('animplayer_invalid')
		return
	if !is_instance_valid(self.pluginInstance.animationPlayerEditor):
		pluginInstance._get_editor_references()
	if !poselib_animPlayer.has_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text):
		return
	var anim :Animation= poselib_animPlayer.get_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var animRoot: Node = poselib_animPlayer.get_node(poselib_animPlayer.root_node)
	var poseRoot: Node = get_tree().edited_scene_root.get_node(poselib_scene)
	
	
	if !is_instance_valid(currentPoselib):
		return
	if !currentPoselib.poseData.has(poselib_template):
		return
	if !currentPoselib.poseData[poselib_template].has(poselib_collection):
		return
	if pose_id > currentPoselib.poseData[poselib_template][poselib_collection].size():
		print('[posepal] posedata not have ',pose_id)
		return
	
	var final_pose: Dictionary
	if optionsData.key_template:
		final_pose = currentPoselib.templateData[poselib_template].duplicate(true)
		for np_id in final_pose:
			var nodepath: String = currentPoselib.get_nodepath_from_id(np_id)
			for property in final_pose[np_id]:
				if final_pose[np_id][property].has('out'):
					continue
#				final_pose[np_id][property]['out'] = 1.0 # Mabye dont override anything so godot chooses
		var _pose: Dictionary = currentPoselib.poseData[poselib_template][poselib_collection][pose_id].duplicate(true)
		for np_id  in _pose:
			var nodepath = np_id
			if !final_pose.has(np_id):
				final_pose[np_id] = {}
			for property in _pose[np_id]:
				final_pose[np_id][property] = _pose[np_id][property]
	else:
		final_pose = currentPoselib.poseData[poselib_template][poselib_collection][pose_id].duplicate()
	if final_pose.has('_name'):
		final_pose.erase('_name')
	
	if queuedPoseData.size() > 0:
		_key_queued_pose(final_pose)
	var current_time: float = float(pluginInstance.animationPlayerEditor_CurrentTime_LineEdit.text)
	for np_id in final_pose:
		var nodepath: String = currentPoselib.get_nodepath_from_id(np_id)
		var node: Node = poseRoot.get_node_or_null(nodepath)
		if !is_instance_valid(node):
			_debug_pose_broken_paths_num +=1
			continue
		
		for property in final_pose[np_id]:
			if property == '_data':
				continue
			var track_path: String = str(animRoot.get_path_to(node))+':'+property
			var tr_property: int = anim.find_track(track_path)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, track_path)
				if final_pose[np_id][property].has('upmo'):
					anim.value_track_set_update_mode(tr_property, final_pose[np_id][property]['upmo'])
			
			var key_value
			if final_pose[np_id][property].has('val'):
				key_value = final_pose[np_id][property]['val']
			elif final_pose[np_id][property].has('valr'):
				key_value = currentPoselib.get_res_from_id(final_pose[np_id][property]['valr'])
			else:
				continue
			
#			if _is_new_track:
#				var update_mode: int = anim.UPDATE_CONTINUOUS
#				if key_value is Object or key_value is String or key_value is bool:
#					update_mode = anim.UPDATE_DISCRETE
#				anim.value_track_set_update_mode(tr_property, )
			
			var key_last: int = anim.track_find_key(tr_property, current_time - 0.01, false)
			if key_last != -1:
				if optionsData.dont_key_duplicate:
					if anim.track_get_key_value(tr_property, key_last) == key_value:
						continue
				if final_pose[np_id][property].has('in'):
					anim.track_set_key_transition(tr_property, key_last, final_pose[np_id][property]['in'])
			if final_pose[np_id][property].has('out'):
				anim.track_insert_key(tr_property, current_time, key_value, final_pose[np_id][property]['out'])
		
		if node.is_class('Polygon2D') && final_pose[np_id].has('_data'):
			for property in PolygonDataProperties:
				var track_path: String = str(animRoot.get_path_to(node))+':'+property
				var tr_property: int = anim.find_track(track_path)
				if tr_property == -1:
					tr_property = anim.add_track(Animation.TYPE_VALUE)
					anim.track_set_path(tr_property, track_path)
					anim.value_track_set_update_mode(tr_property, anim.UPDATE_DISCRETE)
				
				var key_last: int = anim.track_find_key(tr_property, current_time - 0.01, false)
				var key_value = final_pose[np_id]['_data'][property]
				if key_last != -1:
					if anim.track_get_key_value(tr_property, key_last) == key_value:
						continue
				anim.track_insert_key(tr_property, current_time, key_value, 0.0)
				
	if _debug_pose_broken_paths_num > 0:
		issue_warning("broken_nodepaths")
		print("[posepal] Couldn't finish keying pose because "+ str(_debug_pose_broken_paths_num)+
				" broken nodepaths were found.")
	_debug_pose_broken_paths_num = 0
