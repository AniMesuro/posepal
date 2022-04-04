tool
extends Control

# posepal Dock
#export var debug_mode: bool = false

signal updated_reference (reference_name)
signal pose_selected (pose_id)

signal warning_issued (warning_message)
signal warning_fixed (warning_message)

signal issued_forced_selection
signal pose_created (pose_id)

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")
const RES_PosePalSettings: GDScript = preload("res://addons/posepal/PosePalSettings.gd")

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorControl: Control setget ,_get_editorControl

var poselib_scene: String = "" # Nodepath to a scene that holds a Poselib.
var poselib_filter: String = "" # Pose template and Node filter.
var poselib_template: String = "" # Stores subcollections and template pose data.
var poselib_collection: String = "" # Stores pose data.
var poselib_animPlayer: AnimationPlayer # AnimationPlayer from edited scene to make changes to.

var optionsData: Dictionary = {
	'ignore_scene_pose': false,
	'key_template': false,
	'dont_key_duplicate': false
}

var poseFile_path: String = ""
var poseData: Dictionary = {}

var queuedPoseData: Dictionary = {}
var queued_key_time: float = -1.0

var settings: Resource
var current_poselib: Resource
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

func fix_warning(warning :String):
	emit_signal("warning_fixed", warning)
	
func issue_warning(warning :String):
	emit_signal("warning_issued", warning)

func load_poseData() -> int:
	if poselib_scene == "":
		current_poselib = null
		return FAILED
	
#	If the poslib is created at the first time, it will only save to file
#	When the first pose is saved.
	var sceneNode: Node = get_tree().edited_scene_root.get_node(poselib_scene)

	var f: File = File.new()
	if !f.file_exists(poseFile_path):
		poseFile_path = ''
		if !is_instance_valid(current_poselib):
			current_poselib = RES_PoseLibrary.new()
#			Shoudn't be necessary but it somehow still references values from previous poselibs.
			current_poselib.clear()
		return OK
	current_poselib = load(poseFile_path)
	var err: int = current_poselib.prepare_loading_resourceReferences()
	current_poselib.owner_filepath = sceneNode.filename
	
	return err

func save_poseData():
	var selectedScene: Node= get_tree().edited_scene_root.get_node_or_null(poselib_scene)
	if !is_instance_valid(selectedScene):
		return
	var settings: Resource = self.pluginInstance.settings
	
	var f: File = File.new()
	var is_poseFile_valid: bool = false
	if selectedScene.has_meta('_plPoseLib_poseFile'):
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
	
	# Reference FilePath to scene's metadata.
	if !is_poseFile_valid:
		var available_path: String = "#"
		var user_extension = settings.PoselibExtensions.keys()[settings.poselib_extension]
		var d: Directory = Directory.new()
		if !d.dir_exists("res://addons/posepal/.poselibs/"):
			d.make_dir("res://addons/posepal/.poselibs/")

		for i in 100:
			available_path = "res://addons/posepal/.poselibs/" + selectedScene.name+"_"+str(i) + ".poselib." + user_extension
			if f.file_exists(available_path):
				continue
			selectedScene.set_meta('_plPoseLib_poseFile', available_path)
			poseFile_path = available_path
			break
			
		if available_path == '#':
			return
	
	if is_instance_valid(current_poselib):
		current_poselib.owner_filepath = selectedScene.filename
		current_poselib.prepare_saving_resourceReferences()
		var err: int = ResourceSaver.save(poseFile_path, current_poselib)
		current_poselib.prepare_loading_resourceReferences()
		if err != OK:
			print('[posepal] saving didnt succeed, error ',err)
		else:
			pass
	return

# Attempt to, not always succeed. Getting the AnimationPlayer directly in the TimelineEditor is impossible.
func get_selected_animationPlayer() -> AnimationPlayer:
	# EditorSelection's AnimationPlayer is prioritized.
	self.pluginInstance._get_editor_references()
	var currentAnimOptionButton: OptionButton = pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
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
	
	# PoseAnimationPlayer should be child of NewPoseButton
	var newPoseButton: Button = self.poseCreationHBox.get_node("NewPoseButton")
	var poseButton_children: Array = newPoseButton.get_children()
	if poseButton_children.size() > 0:
		var animPlayer: AnimationPlayer = newPoseButton.get_children()[0]
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			return animPlayer
		
	if is_instance_valid(poselib_animPlayer):
		if poselib_animPlayer.assigned_animation == currentAnimOptionButton.text:
			return poselib_animPlayer

	return null

func _on_scene_changed(_sceneRoot :Node): #Edited Scene Root
	fix_warning('*')
	poselib_scene = ""
	poselib_template = ""
	poselib_filter = ""
	poselib_collection = ""
	poselib_animPlayer = null
	current_poselib = null
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
	if get_tree().get_nodes_in_group("plugin posepal").size() == 0:
		# queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _get_poseCreationHBox() -> HBoxContainer:
	poseCreationHBox = $"VSplit/ExtraHBox/PoseCreationHBox"
	return poseCreationHBox

func _get_editorControl() -> Control:
	if !is_instance_valid(self.pluginInstance):
		return null
	return self.pluginInstance.get_editor_interface().get_base_control()

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
	
	print('finalpose ',final_pose)
	
	for nodepath in queuedPoseData.keys():
		print('queued ',nodepath)
		for property in queuedPoseData[nodepath].keys():
			var track_path: String = nodepath +':'+ property
			var tr: int = anim.find_track(track_path)
#			print('track ',tr,' ',property)
			if tr == -1:
				continue
			if !final_pose.has(nodepath):
#				print('finalpose doesnt have np', nodepath)
				continue
			var _can_continue: bool = false
			if optionsData.dont_key_duplicate:
				for prop in final_pose[nodepath].keys():
					if prop != property:
						continue
					if final_pose[nodepath][prop].has('val'):
						if queuedPoseData[nodepath][property] == final_pose[nodepath][prop]['val']:#final_pose[nodepath][property]['val']:
							_can_continue = true
							break
					elif final_pose[nodepath][prop].has('valr'):
						if queuedPoseData[nodepath][property] == current_poselib.get_res_from_id(final_pose[nodepath][prop]['valr']):#final_pose[nodepath][property]['val']:
							_can_continue = true
							break
			if _can_continue:
				continue
			anim.track_insert_key(tr, queued_key_time, queuedPoseData[nodepath][property])
	
	var optionKeyingVBox: VBoxContainer = $"VSplit/TabContainer/PoseLib/VBox/OptionsMargin/OptionsVBox/KeyingVBox"
	optionKeyingVBox.is_pose_queued = false

func _on_pose_selected(pose_id :int):
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
	
	
	if !is_instance_valid(current_poselib):
		return
	if !current_poselib.poseData.has(poselib_template):
		return
	if !current_poselib.poseData[poselib_template].has(poselib_collection):
		return
	if pose_id > current_poselib.poseData[poselib_template][poselib_collection].size():
		print('[posepal] posedata not have ',pose_id)
		return
	
	var final_pose: Dictionary
	if optionsData.key_template:
		final_pose = current_poselib.templateData[poselib_template].duplicate(true)
		for nodepath in final_pose:
			for property in final_pose[nodepath]:
				if final_pose[nodepath][property].has('out'):
					continue
				final_pose[nodepath][property]['out'] = 1.0 # Mabye dont override anything so godot chooses
		var _pose: Dictionary = current_poselib.poseData[poselib_template][poselib_collection][pose_id].duplicate(true)
		for nodepath in _pose:
			if !final_pose.has(nodepath):
				final_pose[nodepath] = {}
			for property in _pose[nodepath]:
				final_pose[nodepath][property] = _pose[nodepath][property]
	else:
		final_pose = current_poselib.poseData[poselib_template][poselib_collection][pose_id].duplicate()
	if final_pose.has('_name'):
		final_pose.erase('_name')
	
	if queuedPoseData.size() > 0:
		_key_queued_pose(final_pose)
	
	for nodepath in final_pose:
#		var node: Node = animRoot.get_node(nodepath)
		var node: Node = poseRoot.get_node(nodepath)
		
		for property in final_pose[nodepath]:
			var track_path :String= str(animRoot.get_path_to(node))+':'+property
			var tr_property :int= anim.find_track(track_path)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, track_path)
			var _key_time :float= float(pluginInstance.animationPlayerEditor_CurrentTime_LineEdit.text)
			
			var key_value
			if final_pose[nodepath][property].has('val'):
				key_value = final_pose[nodepath][property]['val']
			elif final_pose[nodepath][property].has('valr'):
				key_value = current_poselib.get_res_from_id(final_pose[nodepath][property]['valr'])
			else:
				continue
			
			var key_last :int= anim.track_find_key(tr_property, _key_time - 0.01, false)
			if key_last != -1:
				if optionsData.dont_key_duplicate:
					if anim.track_get_key_value(tr_property, key_last) == key_value:
						continue
				if final_pose[nodepath][property].has('in'):
					anim.track_set_key_transition(tr_property, key_last, final_pose[nodepath][property]['in'])
			if final_pose[nodepath][property].has('out'):
				anim.track_insert_key(tr_property, _key_time, key_value, final_pose[nodepath][property]['out'])

