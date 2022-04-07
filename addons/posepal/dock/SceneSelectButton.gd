tool
extends "res://addons/posepal/interface/PropertyMenu.gd"

const SCN_ResourceDependencyPopup: PackedScene = preload("res://addons/posepal/resource_dependency_popup/ResourceDependencyPopup.tscn") 

var scene_nodepaths :PoolStringArray
var selected_scene_id :int= -1


func get_child_scenes() -> PoolStringArray:
	var editedSceneRoot :Node= get_tree().edited_scene_root
	
	_get_children_scenes_from(editedSceneRoot, editedSceneRoot, true, 400)
	return scene_nodepaths

var _scene_nodepaths_iter: int = 0
func _get_children_scenes_from(parent: Node, editedSceneRoot: Node, is_root = false, max_iters: int = 0):
	if is_root:
		scene_nodepaths = PoolStringArray(["."])
		_scene_nodepaths_iter = max_iters
	for child in parent.get_children():
		if _scene_nodepaths_iter == 0:
			return
		_scene_nodepaths_iter -= 1
		_get_children_scenes_from(child, editedSceneRoot)
		if child.filename == '':
			continue
		scene_nodepaths.append(str(editedSceneRoot.get_path_to(child)))

func _on_pressed():
	popup = get_popup()
	popup.clear()
	popup.rect_min_size = Vector2(rect_size.x, 0)
#	popup.rect_size = popup.rect_min_size
	popup.set_as_minsize()
	hint_tooltip = ''
	if !is_instance_valid(get_tree().edited_scene_root):
		return
	# Scenes present in the tree.
	scene_nodepaths = get_child_scenes()

	for nodepath in scene_nodepaths:
		if nodepath == '.':
			popup.add_item(get_tree().edited_scene_root.name)
			continue
		popup.add_item(nodepath)
	popup.set_as_minsize()

func _on_id_selected(id :int):
	var selected_scene: Node = get_tree().edited_scene_root.get_node(scene_nodepaths[id])
	owner.poselib_scene = scene_nodepaths[id]
	hint_tooltip = ''
	
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
		var err: int = owner.load_poseData()
		if err == ERR_FILE_MISSING_DEPENDENCIES:
			var resourceDependencyPopup: WindowDialog = SCN_ResourceDependencyPopup.instance()
			resourceDependencyPopup.posePalDock = owner
			add_child(resourceDependencyPopup)
			resourceDependencyPopup.connect("ok_pressed", self, "_on_ResourceDependencyPopup_ok_pressed", [id], CONNECT_ONESHOT)
			return
		
		hint_tooltip = owner.current_poselib.resource_path
	else:
		hint_tooltip = popup.get_item_text(id)+" (unsaved)"
			
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
	text = popup.get_item_text(id).split('/')[-1]
	icon = owner.editorControl.get_icon("PackedScene", "EditorIcons")
	owner.emit_signal("updated_reference", owner_reference)

func _on_ResourceDependencyPopup_ok_pressed(has_missing_dependencies: bool, id: int):
	if has_missing_dependencies:
		return
	_select_scene(id)

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	hint_tooltip = ''
	
	owner.poselib_scene = ""
	owner.poseData = {}
	owner.poseFile_path = ""
