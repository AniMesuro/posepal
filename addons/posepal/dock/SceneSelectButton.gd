tool
extends "res://addons/posepal/interface/PropertyMenu.gd"

const SCN_ResourceDependencyPopup: PackedScene = preload("res://addons/posepal/resource_dependency_popup/ResourceDependencyPopup.tscn") 

var scene_nodepaths :PoolStringArray
var selected_scene_id :int= -1
func _on_pressed():
	popup = get_popup()
	popup.clear()
	
	if !is_instance_valid(get_tree().edited_scene_root):
		return
	# Scenes present in the tree.
	scene_nodepaths = get_child_scenes()

	for nodepath in scene_nodepaths:
		if nodepath == '.':
			popup.add_item(get_tree().edited_scene_root.name)
			continue
		popup.add_item(nodepath)

func get_child_scenes() -> PoolStringArray:
	var editedSceneRoot :Node= get_tree().edited_scene_root
	
	scene_nodepaths = PoolStringArray(["."])
	
	# Searches for scene nodes through 6 layers.
	for child in editedSceneRoot.get_children():
		if !(str(editedSceneRoot.get_path_to(child)) in scene_nodepaths) && child.filename != '':
			scene_nodepaths.append(str(editedSceneRoot.get_path_to(child)))
		for child_a in child.get_children():			
			if !(str(editedSceneRoot.get_path_to(child_a)) in scene_nodepaths) && child_a.filename != '':
				scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_a)))
			for child_b in child_a.get_children():
				if !(str(editedSceneRoot.get_path_to(child_b)) in scene_nodepaths) && child_b.filename != '':
					scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_b)))
				for child_c in child_b.get_children():
					if !(str(editedSceneRoot.get_path_to(child_c)) in scene_nodepaths) && child_c.filename != '':
						scene_nodepaths.append(str(editedSceneRoot.get_path_to(child_c)))
	return scene_nodepaths

func _on_id_selected(id :int):
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
	
	if is_poseFile_valid:
		owner.poselib_scene = scene_nodepaths[id]
		var err: int = owner.load_poseData()
		if err == ERR_FILE_MISSING_DEPENDENCIES:
			var resourceDependencyPopup: WindowDialog = SCN_ResourceDependencyPopup.instance()
			resourceDependencyPopup.posePalDock = owner
			add_child(resourceDependencyPopup)
			resourceDependencyPopup.connect("ok_pressed", self, "_on_ResourceDependencyPopup_ok_pressed", [id], CONNECT_ONESHOT)
			return
			
	_select_scene(id)

func _on_PoseLibrary_updated_reference(reference :String):
	if !is_inside_tree():
		return	
	if !is_instance_valid(get_tree().edited_scene_root):
		_reset_selection()
		return
	var sceneNode :Node= get_tree().edited_scene_root.get_node_or_null(owner.poselib_scene)
	if !is_instance_valid(sceneNode):
		_reset_selection()

func _on_issued_forced_selection():
	pass

func _select_scene(id: int):
	popup = get_popup()
	owner.fix_warning('scene_not_selected')
	text = popup.get_item_text(id)
	icon = owner.editorControl.get_icon("PackedScene", "EditorIcons")
	owner.emit_signal("updated_reference", owner_reference)

func _on_ResourceDependencyPopup_ok_pressed(has_missing_dependencies: bool, id: int):
	if has_missing_dependencies:
		return
	_select_scene(id)

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
	owner.poselib_scene = ""
	owner.poseData = {}
	owner.poseFile_path = ""
