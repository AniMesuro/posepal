tool
extends Control

# PosePal Dock

signal updated_reference (reference_name)
signal pose_selected (pose_id)

signal warning_issued (warning_message)
signal warning_fixed (warning_message)

signal issued_forced_selection
#signal pose_created (pose, pose_key)

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")
const RES_PosePalSettings: Script = preload("res://addons/posepal/PosePalSettings.gd")

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorControl: Control setget ,_get_editorControl

var poselib_scene: String = "" # Nodepath to a scene that holds a Poselib.
#var poselib_template: String = "" # Group of nodes from a Filter Pose.
var poselib_filter: String = "" # Pose template and Node filter.
var poselib_template: String = "" # Stores subcollections.
var poselib_collection: String = "" # Stores pose data.
var poselib_animPlayer: AnimationPlayer # AnimationPlayer selected on Animation panel.


var optionsData: Dictionary = {
	'ignore_scene_pose': false,
	'key_template': false,
	'dont_key_duplicate': false
}


var poseFile_path: String = ""
# Old - JSON
var poseData: Dictionary = {}

var queuedPoseData: Dictionary = {}
var queued_key_time: float = -1.0

# New - Resource
var current_poselib: RES_PoseLibrary
var wf_current_poselib: WeakRef

var warningIcon :TextureRect
var posePalette: GridContainer setget ,_get_posePalette
var poseCreationHBox: HBoxContainer setget ,_get_poseCreationHBox
func _enter_tree() -> void:
#	pluginInstance = _get_pluginInstance()
	warningIcon = $"VSplit/ExtraHBox/WarningIcon"
#	posePalette = $"VSplit/TabContainer/Palette/GridContainer"
	poseCreationHBox = $"VSplit/ExtraHBox/PoseCreationHBox"
#	yield(get_tree(), "idle_frame")
	if get_tree().edited_scene_root == self:
		return
	editorControl = pluginInstance.editorControl
	
	# Clear stray instances of invalid docks.
	var _dock_group: String = "plugindock posepal"
	for dock in get_tree().get_nodes_in_group(_dock_group):
		dock.queue_free()
		print("PosePal cleansed invalid dock.")
	add_to_group(_dock_group)
	wf_current_poselib = WeakRef.new()

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	connect("pose_selected", self, "_on_pose_selected")
	pluginInstance.connect("scene_changed", self, "_on_scene_changed")
#	connect("script_changed", self, "_on_script_changed")
	

#func _on_script_changed():
#	for option in optionsData:
#		var optionsHBox: VBoxContainer = $"VSplit/TabContainer/PoseLib/VBox/OptionsVBox"
#		optionsHBox.refresh_ui()

func get_relevant_children() -> Array:
	var editedSceneRoot = get_tree().edited_scene_root
	var edited_scene_tree :Array= []
	
	#For each child and its 5 children layers, reference itself to the edited_scene_tree Array
	for child in editedSceneRoot.get_children():
		edited_scene_tree.append(child)
		
		for child_a in child.get_children():
			edited_scene_tree.append(child_a)
			
			for child_b in child_a.get_children():
				edited_scene_tree.append(child_b)
				
				for child_c in child_b.get_children():
					edited_scene_tree.append(child_c)
					
					for child_d in child_c.get_children():
						edited_scene_tree.append(child_d)
						
						for child_e in child_d.get_children():
							edited_scene_tree.append(child_e)
	return edited_scene_tree

func fix_warning(warning :String):
	emit_signal("warning_fixed", warning)
	
func issue_warning(warning :String):
	emit_signal("warning_issued", warning)


func load_poseData() -> void:
	# Checks if owner's posefile is valid
	if poselib_scene == "":
		current_poselib = null
		return
#	if poseFile_path == "":
#		current_poselib = null
#		return
	
#	If the poslib is created at the first time, it will only save to file
#	When the first pose is saved.
	var sceneNode: Node = get_tree().edited_scene_root.get_node(poselib_scene)
#	if is_instance_valid(current_poselib):
#		if current_poselib.owner_filepath != sceneNode.filename:
#			current_poselib.queue_free()

#	if !is_instance_valid(current_poselib):
	var f: File = File.new()
	if !f.file_exists(poseFile_path):
		if !is_instance_valid(current_poselib):
			current_poselib = RES_PoseLibrary.new()
			current_poselib.owner_filepath = sceneNode.filename
		return
	current_poselib = load(poseFile_path)
#	else:
#	wf_current_poselib = weakref(current_poselib)
#	if is_instance_valid(current_poselib):
#		current_poselib.load_lib(poseFile_path)
#	else:
#		current_poselib = RES_PoseLibrary.new()
#		current_poselib.load_lib(poseFile_path)
	
	return


func save_poseData():
	var selectedScene: Node= get_tree().edited_scene_root.get_node_or_null(poselib_scene)
	if !is_instance_valid(selectedScene):
		return
	var settings: RES_PosePalSettings = self.pluginInstance.settings
	
	print('saving poselib')
	# Get FilePath.
	var f: File = File.new()
	var is_poseFile_valid: bool = false
	if selectedScene.has_meta('_plPoseLib_poseFile'):
		if f.file_exists(selectedScene.get_meta('_plPoseLib_poseFile')):
			var filename_pieces: PoolStringArray = selectedScene.get_meta('_plPoseLib_poseFile').get_file().split(".", false, 2)
#			print('filename pieces ',filename_pieces)
			if (filename_pieces[1] == "poselib"
#			&& (filename_pieces[2] == "res")):
			&& (filename_pieces[2] == "tres" or filename_pieces[2] == "res")):
				
#			if selectedScene.get_meta('_plPoseLib_poseFile').get_extension() == 'poselib':
				
				poseFile_path = selectedScene.get_meta('_plPoseLib_poseFile')
				is_poseFile_valid = true
	
	# Reference FilePath to scene's metadata.
	if !is_poseFile_valid:
		var available_path: String = "#"
		var user_extension = settings.PoselibExtensions[settings.poselib_extension]
		for i in 100:
			available_path = "res://addons/posepal/.poselibs/" + selectedScene.name+"_"+str(i) + ".poselib.res"
			if f.file_exists(available_path):
				continue
			selectedScene.set_meta('_plPoseLib_poseFile', available_path)
			poseFile_path = available_path
			break
			
		if available_path == '#':
			return
	
	# NEW # RESOURCE SAVE
	if is_instance_valid(current_poselib):
#		print('poselib res saving')
#		print('poselib exts ',ResourceSaver.get_recognized_extensions(current_poselib))
		var err: int = ResourceSaver.save(poseFile_path, current_poselib)
		if err != OK:
			print('saving didnt succeed, error ',err)
		else:
			pass
#			print('saving poselib ',current_poselib.poseData)
#			print('save successful')
#		current_poselib.save_lib(poseFile_path)
#		return
	
	# OLD # JSON SAVE
	return
	# Save PoseData to PoseFile.
#	var json_poseData: Dictionary= get_json_poseData(poseData)
#
#	f.open(poseFile_path, f.WRITE_READ)
#	f.store_string(JSON.print(json_poseData," "))
#	f.close()

#func get_json_poseData(poseData: Dictionary) -> Dictionary:
##	Loops through every property from every group and face
##	And converts it to a more json friendly format.
#	var selectedScene :Node= get_tree().edited_scene_root.get_node_or_null(poselib_scene)
#	if !is_instance_valid(selectedScene):
#		return {}
#
#	var json_poseData: Dictionary = poseData
#
##	return new_poseData
#	for group in poseData['groups']:
#		for nodepath in poseData['groups'][group]:
#			var selectedNode: Node = selectedScene.get_node(nodepath)
#			for property in poseData['groups'][group][nodepath]:
#				match typeof(selectedNode.get(property)):
#					TYPE_VECTOR2:
#						print('group ',group,' vec2: ', poseData['groups'][group][nodepath][property]['val'])
#						json_poseData['groups'][group][nodepath][property]['val'] = [
#							poseData['groups'][group][nodepath][property]['val'].x,
#							poseData['groups'][group][nodepath][property]['val'].y
#						]
#					TYPE_OBJECT:
#						print('group ',group,' is ',json_poseData['groups'][group][nodepath][property]['val'])
#						if selectedNode.get(property) is Resource:
##							if 	typeof(poseData['groups'][group][nodepath][property]['val']) == TYPE_STRING:
##								var property_resource_path: String = poseData['groups'][group][nodepath][property]['val']
###										print('RESOURCE = ',resource)
##								json_poseData['groups'][group][nodepath][property]['val'] = property_resource_path
#							if typeof(poseData['groups'][group][nodepath][property]['val']) == TYPE_OBJECT:
##										print("!!", property," is type ",typeof(poseData[group][face][pose][nodepath][property]))
#								json_poseData['groups'][group][nodepath][property]['val'] = poseData['groups'][group][nodepath][property]['val'].resource_path
#	for col in poseData['collections']:
#		for collection in poseData['collections'][col]:
#			for pose in poseData['collections'][col][collection]:
#				for nodepath in poseData['collections'][col][collection][pose]:
#					var selectedNode: Node = selectedScene.get_node(nodepath)
#					for property in poseData['collections'][col][collection][pose][nodepath]:
##						print('PROPERTY =  ',property,' ',poseData['collections'][col][collection][pose][nodepath][property]['val'])
#						match typeof(selectedNode.get(property)):
#							TYPE_VECTOR2:
#								json_poseData['collections'][col][collection][pose][nodepath][property]['val'] = [
#									poseData['collections'][col][collection][pose][nodepath][property]['val'].x,#.x
#									poseData['collections'][col][collection][pose][nodepath][property]['val'].y#.y
#									]
##								print(';vector2 ',json_poseData['collections'][col][collection][pose][nodepath][property])
#							TYPE_OBJECT:
#								if selectedNode.get(property) is Resource:
#									if 	typeof(poseData['collections'][col][collection][pose][nodepath][property]['val']) == TYPE_STRING:
#										var property_resource_path :String= poseData['collections'][col][collection][pose][nodepath][property]['val']
##										print('RESOURCE = ',resource)
#										json_poseData['collections'][col][collection][pose][nodepath][property]['val'] = property_resource_path
#									elif typeof(poseData['collections'][col][collection][pose][nodepath][property]['val']) == TYPE_OBJECT:
##										print("!!", property," is type ",typeof(poseData[group][face][pose][nodepath][property]))
#										json_poseData['collections'][col][collection][pose][nodepath][property]['val'] = poseData['collections'][col][collection][pose][nodepath][property]['val'].resource_path
#
#	return json_poseData

# Attempt to
func get_selected_animationPlayer() -> AnimationPlayer:
	# PoseAnimationPlayer is prioritized.
	var currentAnimOptionButton: OptionButton = self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var editorInterface: EditorInterface = pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	for selectedNode in editorSelection.get_selected_nodes():
		if selectedNode.get_class() != 'AnimationPlayer':
			continue
		var animPlayer: AnimationPlayer = selectedNode
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			return animPlayer
	
	var newPoseButton: Button = self.poseCreationHBox.get_node("NewPoseButton")
	# PoseAnimationPlayer should be child of NewPoseButton
	var poseButton_children: Array = newPoseButton.get_children()
	if poseButton_children.size() > 0:
		var animPlayer: AnimationPlayer = newPoseButton.get_children()[0]
		if animPlayer.assigned_animation == currentAnimOptionButton.text:
			return animPlayer
		
	if is_instance_valid(poselib_animPlayer):
		if poselib_animPlayer.assigned_animation == currentAnimOptionButton.text:
			return poselib_animPlayer

#	print('[PosePal] No AnimationPlayer found in AnimationPlayerEditor')
	return null

func get_editor_poseData(jsonPoseData :Dictionary) -> Dictionary:
#	print('jsonPoseData = ',jsonPoseData)
	var selectedScene :Node= get_tree().edited_scene_root.get_node_or_null(poselib_scene)
	if !is_instance_valid(selectedScene):
		return {}
	
	if !jsonPoseData.has('collections'):
		print('posedata doesnt have collections')
		return {}
	if !jsonPoseData.has('groups'):
		jsonPoseData.groups = {'all':{}}
	var new_poseData :Dictionary= jsonPoseData
	#print(new_poseData)
#	print('getting editor posedata')
#	return jsonPoseData
	for group in jsonPoseData['groups']:
		for nodepath in jsonPoseData['groups'][group]:
			var selectedNode: Node = selectedScene.get_node(nodepath)
#			print('--[gr] ',group,'/',nodepath,':::',new_poseData['groups'][group][nodepath])
			for property in jsonPoseData['groups'][group][nodepath]:
#				print('++ GR ',group,'/',nodepath,':', property,'= ',new_poseData['groups'][group][nodepath][property]['val'])
				match typeof(selectedNode.get(property)):
					TYPE_VECTOR2:
#						print('load group ',group,' vec2= ',new_poseData['groups'][group][nodepath][property]['val'])
						new_poseData['groups'][group][nodepath][property]['val'] = Vector2(
							jsonPoseData['groups'][group][nodepath][property]['val'][0],
							jsonPoseData['groups'][group][nodepath][property]['val'][1]
						)
					TYPE_OBJECT:
#						print('load group ',group,' obj= ',new_poseData['groups'][group][nodepath][property]['val'])
						if typeof(jsonPoseData['groups'][group][nodepath][property]['val']) == TYPE_STRING:
							var resource_path: String = jsonPoseData['groups'][group][nodepath][property]['val']
							var f: File = File.new()
							if !f.file_exists(resource_path):
								new_poseData['groups'][group][nodepath].erase(property)
								continue
							new_poseData['groups'][group][nodepath][property]['val'] = load(resource_path)
	for col in jsonPoseData['collections']:
		for collection in jsonPoseData['collections'][col]:
			for pose in jsonPoseData['collections'][col][collection]:
				for nodepath in jsonPoseData['collections'][col][collection][pose]:
					var selectedNode: Node = selectedScene.get_node(nodepath)#poseData[group][face][pose][nodepath])
					for property in jsonPoseData['collections'][col][collection][pose][nodepath]:
#						print(property,' ',jsonPoseData[group][face][pose][nodepath][property],' ',typeof(selectedNode.get(property)))#jsonPoseData[group][face][pose][nodepath][property])))
						match typeof(selectedNode.get(property)):
							TYPE_VECTOR2:
#								print(';vector2 ',new_poseData[group][face][pose][nodepath][property])
								new_poseData['collections'][col][collection][pose][nodepath][property]['val'] = Vector2(
									jsonPoseData['collections'][col][collection][pose][nodepath][property]['val'][0], # x
									jsonPoseData['collections'][col][collection][pose][nodepath][property]['val'][1] 	# y
									)
							TYPE_OBJECT:
								var property_filepath :String= jsonPoseData['collections'][col][collection][pose][nodepath][property]['val']
								var f :File= File.new()
								if !f.file_exists(property_filepath):
									new_poseData['collections'][col][collection][pose][nodepath].erase(property)
									continue
								else:
									new_poseData['collections'][col][collection][pose][nodepath][property]['val'] = load(property_filepath)
#									print('StreamTetxure  ',new_poseData['collections'][col][collection][pose][nodepath][property]['val'])
	return new_poseData

#func get_editorControl() -> Control:
#	if !is_instance_valid(self):
#		print(self,' not valid')
#	if !is_inside_tree():
#		print(self, ' not inside tree')
#
##	pluginInstance = _get_pluginInstance()
#	return pluginInstance.get_editor_interface().get_base_control()

func _on_scene_changed(_sceneRoot :Node): #Edited Scene Root

	fix_warning('*')
	poselib_scene = ""
	poselib_template = ""
	poselib_filter = ""
	poselib_collection = ""
	poselib_animPlayer = null
#	poseData = {}
	current_poselib = null
	emit_signal("updated_reference", "poselib_scene")
#	if is_instance_valid(_sceneRoot):#get_tree().edited_scene_root):
#		fix_warning('edited_scene_invalid')
	
	
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
		queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _get_poseCreationHBox() -> HBoxContainer:
	poseCreationHBox = $"VSplit/ExtraHBox/PoseCreationHBox"
	return poseCreationHBox

func _get_editorControl() -> Control:
#	if is_instance_valid(editorControl):
#		return editorControl
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
		
#	print("current anim =",self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var anim :Animation= poselib_animPlayer.get_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var animRoot :Node= poselib_animPlayer.get_node(poselib_animPlayer.root_node)
	
	
#	var final_pose: Dictionary
#	if optionsData.key_template:
#		final_pose = current_poselib.templateData[poselib_template].duplicate(true)
#	final_pose = current_poselib.poseData[poselib_template][poselib_collection][final_pose_id].duplicate(true)
	print('fin size ',final_pose.size())
	print(final_pose.keys())
#	if final_pose.has('_name'):
#		final_pose.erase('_name')
		
	for nodepath in queuedPoseData.keys():
		for property in queuedPoseData[nodepath].keys():
			var track_path: String = nodepath +':'+ property
			var tr: int = anim.find_track(track_path)
			if tr == -1:
				continue
#			var track_path: NodePath = nodepath + ':' + queuedPoseData[nodepath] #currentAnimation.track_get_path(tr) # (@@@)/./Sprite:position
#		var property: String = queuedPoseData[nodepath]
#		var path_subnames: NodePath = track_path.get_concatenated_subnames() # :position
#		var node_path: String = str(track_path).trim_suffix(str(path_subnames)).rstrip(':') # Sprite
#		if node_path == '':
#			node_path = '.'
#		if queuedPoseData[nodepath] == null:
#			continue
#		print('@@@finalpose ',str(path_subnames).rstrip(':'))
			if !final_pose.has(nodepath):
				continue
#			if final_pose[nodepath]
#			print(final_pose[nodepath].keys())
#			print(final_pose[nodepath].keys()[0])
			
#			print(final_pose[nodepath].keys().has(property))
#			print(property in final_pose[nodepath].keys())
#			print(property in final_pose[nodepath])
#			print(final_pose[nodepath].keys().has("position"))
			
#			if final_pose[nodepath].keys().has(get(property)):
#				print('aaaa')
#			if !final_pose[nodepath].has(property):
#				print('ulllll')
#			print('finalpose ',property,' ', final_pose[nodepath].get(property))
#			print('finalpose ',property,' ', current_poselib.poseData[poselib_template][poselib_collection][final_pose_id].get(property))
			
			
#			if final_pose[nodepath].get(property)==null:
#				continue
				
#			print('passed ',final_pose[nodepath][property])
#			print(final_pose[nodepath])
#
#			if property in final_pose[nodepath].keys():
#				print(final_pose[nodepath][property])
#			print('passed1 ',final_pose[nodepath][property]['val'])
			var _can_continue: bool = false
			if optionsData.dont_key_duplicate:
				for prop in final_pose[nodepath].keys():
#					print('prop ',nodepath,' ',prop)
#					print(final_pose[nodepath][prop])
#					print()
					if prop != property:
						continue
					if queuedPoseData[nodepath][property] == final_pose[nodepath][prop]['val']:#final_pose[nodepath][property]['val']:
#						print('fpose ',nodepath,' ',prop)
						_can_continue = true
						break
			if _can_continue:
				continue
			anim.track_insert_key(tr, queued_key_time, queuedPoseData[nodepath][property])
	
	
	
	
#	var optionsVBox: VBoxContainer = $"VSplit/TabContainer/PoseLib/VBox/OptionsVBox"
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
	print("current anim =",self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var anim :Animation= poselib_animPlayer.get_animation(self.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var animRoot :Node= poselib_animPlayer.get_node(poselib_animPlayer.root_node)
	
	if !is_instance_valid(current_poselib):
		print('error n1')
		return
	if !current_poselib.poseData.has(poselib_template):
		print('error n1')
		return
	if !current_poselib.poseData[poselib_template].has(poselib_collection):
		print('error n2')
		return
	if pose_id > current_poselib.poseData[poselib_template][poselib_collection].size():
		print('posedata not have ',pose_id)
		return
	
#	print(current_poselib.poseData)
	var final_pose: Dictionary
	if optionsData.key_template:
		final_pose = current_poselib.templateData[poselib_template].duplicate(true)
		for nodepath in final_pose:
			for property in final_pose[nodepath]:
				final_pose[nodepath][property]['out'] = 0.0
#		print('fin ',final_pose)
		var _pose: Dictionary = current_poselib.poseData[poselib_template][poselib_collection][pose_id].duplicate(true)
		print('___template key___')
		for nodepath in _pose:
#			print('@@'+nodepath)
			if !final_pose.has(nodepath):
				final_pose[nodepath] = {}
			for property in _pose[nodepath]:
#				print('___add_property')
				final_pose[nodepath][property] = _pose[nodepath][property]
		print('finalpose = ', final_pose.size(),'\n pose = ',_pose.size())
#		print('@finalpose =',final_pose)
#		print('@_pose =',_pose)
	else:
		final_pose = current_poselib.poseData[poselib_template][poselib_collection][pose_id].duplicate()
	if final_pose.has('_name'):
		final_pose.erase('_name')
	
	if queuedPoseData.size() > 0:
		_key_queued_pose(final_pose)
	
	for nodepath in final_pose:
		var node: Node = animRoot.get_node(nodepath)
		
		for property in final_pose[nodepath]:
			var track_path :String= str(animRoot.get_path_to(node))+':'+property
			var tr_property :int= anim.find_track(track_path)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, track_path)
			var _key_time :float= float(pluginInstance.animationPlayerEditor_CurrentTime_LineEdit.text)
			
			var key_value
			# Converts the json values to corresponding type.
#			match typeof(node.get(property)):
#				_:
			key_value = final_pose[nodepath][property]['val']
#			Selects key before current_key and changes its transition for "in"
			var key_last :int= anim.track_find_key(tr_property, _key_time - 0.01, false)
			if key_last != -1:
				if optionsData.dont_key_duplicate:
					if anim.track_get_key_value(tr_property, key_last) == key_value:
						continue
				if final_pose[nodepath][property].has('in'):
					anim.track_set_key_transition(tr_property, key_last, final_pose[nodepath][property]['in'])
			if final_pose[nodepath][property].has('out'):
				anim.track_insert_key(tr_property, _key_time, key_value, final_pose[nodepath][property]['out'])
			#
			
	
#	print('pose_id =',pose_id)

func _on_pose_created(pose :Dictionary, pose_key :String):
#	pluginInstance = _get_pluginInstance()
#	var poseFile_path = pluginInstance.tscn_set_poseFile(poselib_scene, poselib_scene.get_basename().get_file()) # Pose File has  same name as scene (though there will be an id for how many dupplicates there are)
	print("posepath = ",poseFile_path)
	
	poseData['collections'][poselib_template][poselib_collection][pose_key] = pose
	save_poseData()
	
	posePalette = self.posePalette
	posePalette.fill_previews()
	# Get PoseFile
#	var f :File= File.new()
#	var selected_scene :Node= get_tree().edited_scene_root.get_node(poselib_scene)
#	if selected_scene.has_meta('_plPoseLib_poseFile'):
#		if f.file_exists(selected_scene.get_meta('_plPoseLib_poseFile')):
#			if selected_scene.get_meta('_plPoseLib_poseFile').get_extension() == 'pose':
#				poseFile_path = selected_scene.get_meta('_plPoseLib_poseFile')
				
#				return
#	if poseFile_path
	# Save PoseFile
#	f.open(

# load_poseData

#func create_poselib():
	
