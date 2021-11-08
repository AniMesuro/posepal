tool
extends "res://addons/posepal/interface/PropertyMenu.gd"



#var scene_paths :PoolStringArray
var scene_nodepaths :PoolStringArray
var selected_scene_id :int= -1
func _on_pressed():
	print('scn select click')
	popup = get_popup()
	popup.clear()
#	popup.rect_size = rect_min_size
	
	if !is_instance_valid(get_tree().edited_scene_root):
		return
	# Scenes present in the tree.
	scene_nodepaths = get_child_scenes()
	
		

#	print(tscn_block,"\n------")
#	print(tscn_ext_resource)
#	print(scene_nodepaths)
	for nodepath in scene_nodepaths:
#		var scene :Node= get_node(nodepath)
		if nodepath == '.':
			popup.add_item(get_tree().edited_scene_root.name)
			continue
		popup.add_item(nodepath)

func get_child_scenes() -> PoolStringArray:
	var editedSceneRoot :Node= get_tree().edited_scene_root
	
#	scene_paths = PoolStringArray([get_tree().edited_scene_root.filename])
	scene_nodepaths = PoolStringArray(["."])
	
	# Searches for scene nodes through 6 layers.
	for child in editedSceneRoot.get_children():
#		if !child.filename in scene_paths && child.filename != '':
		if !(str(editedSceneRoot.get_path_to(child)) in scene_nodepaths) && child.filename != '':
#			scene_paths.append(child.filename)
			scene_nodepaths.append(str(editedSceneRoot.get_path_to(child)))
			
		for child_a in child.get_children():			
			if !(str(editedSceneRoot.get_path_to(child_a)) in scene_nodepaths) && child_a.filename != '':
#				scene_paths.append(child_a.filename)
				scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_a)))
				
			for child_b in child_a.get_children():
				if !(str(editedSceneRoot.get_path_to(child_b)) in scene_nodepaths) && child_b.filename != '':
#					scene_paths.append(child_b.filename)
					scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_b)))
					
				for child_c in child_b.get_children():
					if !(str(editedSceneRoot.get_path_to(child_c)) in scene_nodepaths) && child_c.filename != '':
#						scene_paths.append(child_c.filename)
						scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_c)))
			
	return scene_nodepaths

func _on_id_selected(id :int):
	owner.poselib_scene = scene_nodepaths[id]
	owner.fix_warning('scene_not_selected')
	text = popup.get_item_text(id)
	icon = owner.editorControl.get_icon("PackedScene", "EditorIcons")
	owner.emit_signal("updated_reference", owner_reference)
	var selected_scene: Node = get_tree().edited_scene_root.get_node(scene_nodepaths[id])
	
#	Only read poseFile
	var is_poseFile_valid: bool = false
	if selected_scene.has_meta('_plPoseLib_poseFile'):
		var f :File= File.new()
		if f.file_exists(selected_scene.get_meta('_plPoseLib_poseFile')):
			var filename_pieces: PoolStringArray = selected_scene.get_meta('_plPoseLib_poseFile').get_file().split(".", false, 2)
			if (filename_pieces[1] == "poselib"
			&& (filename_pieces[2] == "tres" or filename_pieces[2] == "res")):
				owner.poseFile_path = selected_scene.get_meta('_plPoseLib_poseFile')
				is_poseFile_valid = true
	
	# NEW WAY # RESOURCE SAVE
	if is_poseFile_valid:
		print('loading scene poselib')
		owner.load_poseData()
#	if is_poseFile_valid:
#		owner.load_poseData()
#	else:
#		owner.current_poselib = owner.RES_PoseLibrary.new()
	
	# OLD WAY # JSON SAVE
	return
#	Create default group and face to PoseData if PoseFile invalid.
	if is_poseFile_valid:
		owner.load_poseData()
	
	if !owner.poseData.has('groups'):
		owner.poseData['groups'] = {}
	if !owner.poseData['groups'].has('all'):
		owner.poseData['groups']['all'] = {}
	if !owner.poseData.has('collections'):
		owner.poseData['collections'] = {}
	if !owner.poseData['collections'].has('default'):
		owner.poseData['collections']['default'] = {}
	if !owner.poseData['collections']['default'].has('default'):
		owner.poseData['collections']['default']['default'] = {}
		
	owner.poselib_template = 'default'
	owner.poselib_collection = 'default'
	owner.poselib_template = 'all'
	owner.emit_signal("issued_forced_selection")
#	print('scene select =',owner.poseData['groups'])
#	else:
#		owner.load_poseData()
#		if !owner.poseData.has('collections'):
#			owner.poseData['collections'] = {}
#			owner.poseData['collections']['default'] = {}
#			owner.poseData['collections']['default']['default'] = {}
	# Reference poseFile
#	var available_path :String
#	var f :File= File.new()
#	for i in 100:
#		available_path = "res://addons/pose library/.posedata/" + owner.poselib_scene.get_basename().get_file()+"_"+str(i) + ".pose"
#		if f.file_exists(available_path):
#			continue
#		selected_scene.set_meta('_plPoseLib_poseFile', available_path)
#		break
#
#	# Create PoseLib File
#	f.open(available_path, f.WRITE)
#	f.store_string("{}")
#	f.close()
#	owner.poseFile_path = available_path
#	return
		
		
		
#	selected_scene.set_meta("_plposelib_poseFile", TextFile.new())
#	print("scene posefile =",selected_scene.get_meta("_plposelib_poseFile"))

	# Update Pose Pallette ()
	# If new scene, update Group,Face Selectors to the first key.

func _on_PoseLibrary_updated_reference(reference :String):
	if !is_inside_tree():
		return
	
	if !is_instance_valid(get_tree().edited_scene_root):
		_reset_selection()
		return
	var sceneNode :Node= get_tree().edited_scene_root.get_node_or_null(owner.poselib_scene)
	if !is_instance_valid(sceneNode):
		_reset_selection()

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
	owner.poselib_scene = ""
	owner.poseData = {}
	owner.poseFile_path = ""

#func _on_issued_forced_selection():
#	pass
