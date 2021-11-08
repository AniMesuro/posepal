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

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorControl: Control setget ,_get_editorControl

var poselib_scene: String = "" # Nodepath to a scene that holds a Poselib.
#var poselib_template: String = "" # Group of nodes from a Filter Pose.
var poselib_filter: String = "" # Pose template and Node filter.
var poselib_template: String = "" # Stores subcollections.
var poselib_collection: String = "" # Stores pose data.
var poselib_animPlayer: AnimationPlayer # AnimationPlayer selected on Animation panel.


var poseFile_path: String = ""
# Old - JSON
var poseData: Dictionary = {}

# New - Resource
var current_poselib: RES_PoseLibrary
var wf_current_poselib: WeakRef

var warningIcon :TextureRect
var posePalette: GridContainer setget ,_get_posePalette
func _enter_tree() -> void:
#	pluginInstance = _get_pluginInstance()
	warningIcon = $"VSplit/ExtraHBox/WarningIcon"
	posePalette = $"VSplit/TabContainer/Palette/GridContainer"
	
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
	

func _get_pluginInstance() -> EditorPlugin:
	if is_instance_valid(pluginInstance):
		return pluginInstance
	if get_tree().get_nodes_in_group("plugin posepal").size() == 0:
		queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _get_editorControl() -> Control:
	if is_instance_valid(editorControl):
		return editorControl
	return self.pluginInstance.get_editor_interface().get_base_control()

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

func _on_pose_selected(pose_id :int):
#	if !is_instance_valid(pluginInstance):
#		pluginInstance = _get_pluginInstance()
	
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
	
	print(current_poselib.poseData)
	for nodepath in current_poselib.poseData[poselib_template][poselib_collection][pose_id]:
		print(nodepath)
		if nodepath == "_name":
			return
#		print('nodepath ', nodepath)
		var node: Node = animRoot.get_node(nodepath)
#		print('root ',node)
		
		for property in current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath]:
			
			var track_path :String= str(animRoot.get_path_to(node))+':'+property
			var tr_property :int= anim.find_track(track_path)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, track_path)
#			var anim.track_find_key(
			var _key_time :float= float(pluginInstance.animationPlayerEditor_CurrentTime_LineEdit.text)
			
			var key_value
			# Converts the json values to corresponding type.
			match typeof(node.get(property)):
#				TYPE_VECTOR2: #position, scale
#					key_value = Vector2(
#						poseData['collections'][poselib_template][poselib_collection][pose_key][nodepath][property]['val'][0],
#						poseData['collections'][poselib_template][poselib_collection][pose_key][nodepath][property]['val'][1])
#				TYPE_OBJECT: # texture
#					if property != "texture":
#						return
#					var f: File = File.new()
#					if f.file_exists['collections'][poselib_template][poselib_collection][pose_key][nodepath][property]['val']):
#						match poseData['collections'][poselib_template][poselib_collection][pose_key][nodepath][property]['val'].get_extension():
#							'png', 'jpg':
#								key_value = load(poseData['collections'][poselib_template][poselib_collection][pose_key][nodepath][property]['val'])
#							_:
#								return
				_:
					key_value = current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath][property]['val']
#			Selects key before current_key and changes its transition for "in"
			var key_last :int= anim.track_find_key(tr_property, _key_time - 0.01, false)
			if key_last != -1:
				if current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath][property].has('in'):
					anim.track_set_key_transition(tr_property, key_last, current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath][property]['in'])
			if current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath][property].has('out'):
				anim.track_insert_key(tr_property, _key_time, key_value, current_poselib.poseData[poselib_template][poselib_collection][pose_id][nodepath][property]['out'])
			#
			
	
	print('pose_id =',pose_id)

func _on_pose_created(pose :Dictionary, pose_key :String):
#	pluginInstance = _get_pluginInstance()
#	var poseFile_path = pluginInstance.tscn_set_poseFile(poselib_scene, poselib_scene.get_basename().get_file()) # Pose File has  same name as scene (though there will be an id for how many dupplicates there are)
	print("posepath = ",poseFile_path)
	
	poseData['collections'][poselib_template][poselib_collection][pose_key] = pose
	save_poseData()
	
	posePalette = $"VSplit/TabContainer/Palette/GridContainer"
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
	

func load_poseData() -> void:
	# Checks if owner's posefile is valid
	if poselib_scene == "":
		current_poselib = null
		return
#	if poseFile_path == "":
#		current_poselib = null
#		return
	
#	var extension: String = poseFile_path.get_extension()
#	if extension != "poselib":
#		return
	var f: File = File.new()
	if !f.file_exists(poseFile_path):
		current_poselib = RES_PoseLibrary.new()
#		wf_current_poselib = weakref(current_poselib)
		var sceneNode: Node = get_tree().edited_scene_root.get_node(poselib_scene)
		current_poselib.owner_filepath = sceneNode.filename
		return
	current_poselib = load(poseFile_path)
#	wf_current_poselib = weakref(current_poselib)
#	if is_instance_valid(current_poselib):
#		current_poselib.load_lib(poseFile_path)
#	else:
#		current_poselib = RES_PoseLibrary.new()
#		current_poselib.load_lib(poseFile_path)
	
	# OLD #
	return
# Checks if own property is valid.
#	print('loading')
	# Checks if scene is selected
	if poselib_scene == "":
#		print('error')
		return
	# Checks if owner's posefile is valid
	if poseFile_path == "":
#		print('error')
		return
#	var f: File = File.new()
	if !f.file_exists(poseFile_path):
#		print(poseFile_path,' doesnt exist')
		return
	f.open(poseFile_path, f.READ)
	var poseFile_text :String= f.get_as_text()
	f.close()
	
	var jsonResult :JSONParseResult= JSON.parse(poseFile_text)
	if jsonResult.error != OK:
		print('json not ok')
		return
	poseData = get_editor_poseData(jsonResult.result)
	
	if !poseData.has('groups'):
		poseData['groups'] = {}
#		save_poseData()
	if !poseData['groups'].has('all'):
		poseData['groups']['all'] = {}
#		save_poseData()
	if !poseData.has('collections'):
		poseData['collections'] = {}
#		poseData['collections']['default'] = {}
#		poseData['collections']['default']['default'] = {}
#		save_poseData()
#		return
	if !poseData['collections'].has('default'):
		poseData['collections']['default'] = {}
#		poseData['collections']['default']['default'] = {}
#		save_poseData()
	if !poseData['collections']['default'].has('default'):
		poseData['collections']['default']['default'] = {}
#		save_poseData()
	return

func save_poseData():
	var selectedScene: Node= get_tree().edited_scene_root.get_node_or_null(poselib_scene)
	if !is_instance_valid(selectedScene):
		return
	
	print('saving poselib')
	# Get FilePath.
	var f: File = File.new()
	var is_poseFile_valid: bool = false
	if selectedScene.has_meta('_plPoseLib_poseFile'):
		if f.file_exists(selectedScene.get_meta('_plPoseLib_poseFile')):
			var filename_pieces: PoolStringArray = selectedScene.get_meta('_plPoseLib_poseFile').get_file().split(".", false, 2)
#			print('filename pieces ',filename_pieces)
			if (filename_pieces[1] == "poselib"
			&& (filename_pieces[2] == "tres" or filename_pieces[2] == "res")):
#			if selectedScene.get_meta('_plPoseLib_poseFile').get_extension() == 'poselib':
				
				poseFile_path = selectedScene.get_meta('_plPoseLib_poseFile')
				is_poseFile_valid = true
	
	# Reference FilePath to scene's metadata.
	if !is_poseFile_valid:
		var available_path: String = "#"
		for i in 100:
			available_path = "res://addons/posepal/.poselibs/" + selectedScene.name+"_"+str(i) + ".poselib.tres"
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
#		for subcol in poseData['collections'][col]:
#			for pose in poseData['collections'][col][subcol]:
#				for nodepath in poseData['collections'][col][subcol][pose]:
#					var selectedNode: Node = selectedScene.get_node(nodepath)
#					for property in poseData['collections'][col][subcol][pose][nodepath]:
##						print('PROPERTY =  ',property,' ',poseData['collections'][col][subcol][pose][nodepath][property]['val'])
#						match typeof(selectedNode.get(property)):
#							TYPE_VECTOR2:
#								json_poseData['collections'][col][subcol][pose][nodepath][property]['val'] = [
#									poseData['collections'][col][subcol][pose][nodepath][property]['val'].x,#.x
#									poseData['collections'][col][subcol][pose][nodepath][property]['val'].y#.y
#									]
##								print(';vector2 ',json_poseData['collections'][col][subcol][pose][nodepath][property])
#							TYPE_OBJECT:
#								if selectedNode.get(property) is Resource:
#									if 	typeof(poseData['collections'][col][subcol][pose][nodepath][property]['val']) == TYPE_STRING:
#										var property_resource_path :String= poseData['collections'][col][subcol][pose][nodepath][property]['val']
##										print('RESOURCE = ',resource)
#										json_poseData['collections'][col][subcol][pose][nodepath][property]['val'] = property_resource_path
#									elif typeof(poseData['collections'][col][subcol][pose][nodepath][property]['val']) == TYPE_OBJECT:
##										print("!!", property," is type ",typeof(poseData[group][face][pose][nodepath][property]))
#										json_poseData['collections'][col][subcol][pose][nodepath][property]['val'] = poseData['collections'][col][subcol][pose][nodepath][property]['val'].resource_path
#
#	return json_poseData

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
		for subcol in jsonPoseData['collections'][col]:
			for pose in jsonPoseData['collections'][col][subcol]:
				for nodepath in jsonPoseData['collections'][col][subcol][pose]:
					var selectedNode: Node = selectedScene.get_node(nodepath)#poseData[group][face][pose][nodepath])
					for property in jsonPoseData['collections'][col][subcol][pose][nodepath]:
#						print(property,' ',jsonPoseData[group][face][pose][nodepath][property],' ',typeof(selectedNode.get(property)))#jsonPoseData[group][face][pose][nodepath][property])))
						match typeof(selectedNode.get(property)):
							TYPE_VECTOR2:
#								print(';vector2 ',new_poseData[group][face][pose][nodepath][property])
								new_poseData['collections'][col][subcol][pose][nodepath][property]['val'] = Vector2(
									jsonPoseData['collections'][col][subcol][pose][nodepath][property]['val'][0], # x
									jsonPoseData['collections'][col][subcol][pose][nodepath][property]['val'][1] 	# y
									)
							TYPE_OBJECT:
								var property_filepath :String= jsonPoseData['collections'][col][subcol][pose][nodepath][property]['val']
								var f :File= File.new()
								if !f.file_exists(property_filepath):
									new_poseData['collections'][col][subcol][pose][nodepath].erase(property)
									continue
								else:
									new_poseData['collections'][col][subcol][pose][nodepath][property]['val'] = load(property_filepath)
#									print('StreamTetxure  ',new_poseData['collections'][col][subcol][pose][nodepath][property]['val'])
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
	
	
	posePalette = $"VSplit/TabContainer/Palette/GridContainer"
	posePalette.fill_previews()

func _get_posePalette():
	posePalette = $"VSplit/TabContainer/Palette/GridContainer"
	return posePalette
	
