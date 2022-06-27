tool
extends MenuButton

const SCN_FileSelectorPreview: PackedScene = preload("res://addons/posepal/file_selector_preview/FileSelectorPreview.tscn")
const SCN_SetupBonesPopup: PackedScene = preload("res://addons/posepal/setup_bones_popup/SetupBonesPopup.tscn")
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")


enum Items {
	NEW,
	SAVE,
	SAVE_AS,
	LOAD,
	SETUP_BONES
}

func _ready() -> void:
	if get_tree().edited_scene_root == get_parent().owner:
		return
	popupMenu = get_popup()
	popupMenu.clear()
	
	popupMenu.connect("id_pressed", self, "_on_id_pressed")
	connect("pressed", self, "_on_pressed")

var popupMenu: PopupMenu
func _on_pressed():
	if !_is_selected_scene_valid():
		return
	var poselib: RES_PoseLibrary = owner.currentPoselib
	
	popupMenu = get_popup()
	popupMenu.clear()
	popupMenu.rect_min_size = Vector2(rect_size.x, 0)
	
	if is_instance_valid(poselib):
		popupMenu.add_item('New', Items.NEW)
		popupMenu.add_item('Load', Items.LOAD)
		popupMenu.add_item('Save', Items.SAVE)
		popupMenu.add_item('Save as', Items.SAVE_AS)
		
		popupMenu.add_item('Setup bones', Items.SETUP_BONES)
#	else:
#		popupMenu.add_item('Load', Items.LOAD)

func _is_selected_scene_valid() -> bool:
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node_or_null(owner.poselib_scene)
	
	if !is_instance_valid(poseSceneRoot):
		popupMenu.hide()
		owner.issue_warning('scene_not_selected')
		return false
	return true
	
func _on_id_pressed(id: int):
	match id:
		Items.SAVE:
			owner.save_poseData()
		Items.SAVE_AS:
			var pure_old_file: String = owner.currentPoselib.resource_path.get_file().split('.')[0]
			var pure_old_file_parts: PoolStringArray = pure_old_file.split('_', false)
			var pure_file: String = ''
			var scene_name: String = get_tree().edited_scene_root.get_node(owner.poselib_scene).name
			if pure_old_file_parts.size() > 1:
				pure_file = pure_old_file_parts[0]+'_'+str(1 + int(pure_old_file_parts[1]))
			else:
				pure_file = scene_name +'_0'
			
			var fileSelectorPreview = SCN_FileSelectorPreview.instance()
			add_child(fileSelectorPreview)
			
			var title: String
			if pure_old_file  != '':
				title = "Save new poselib based on "+ pure_old_file
			else:
				title = "Save new poselib for scene "+ scene_name
			fileSelectorPreview.setup(FileDialog.ACCESS_RESOURCES, PoolStringArray(['res', 'tres']),
					"* All poselibs", title, FileDialog.MODE_SAVE_FILE)
			
			var poselib_extension: String = owner.settings.PoselibExtensions.keys()[owner.settings.poselib_extension]
			if pure_old_file == '':
				fileSelectorPreview.current_dir = get_tree().edited_scene_root.filename.get_base_dir() + '/'
			else:
				fileSelectorPreview.current_dir = owner.currentPoselib.owner_filepath.get_base_dir() + '/'
			fileSelectorPreview.current_file = pure_file +'.poselib.'+ poselib_extension
			fileSelectorPreview.current_filter = poselib_extension
			
			fileSelectorPreview.connect("file_selected", self, "_on_file_selected", [Items.SAVE_AS], CONNECT_ONESHOT)
			fileSelectorPreview.connect("tree_exited", self, "_on_file_canceled", [], CONNECT_ONESHOT)
		Items.LOAD:
			var last_poselib: RES_PoseLibrary = owner.currentPoselib
			var last_poselib_dir: String = '' 
			if is_instance_valid(last_poselib) && last_poselib.owner_filepath != 'res://':
				last_poselib_dir = last_poselib.resource_path.get_base_dir()+'/'
			
			var fileSelectorPreview = SCN_FileSelectorPreview.instance()
			add_child(fileSelectorPreview)
			
			fileSelectorPreview.setup(FileDialog.ACCESS_RESOURCES, PoolStringArray(['res', 'tres']),
					"* All poselibs", "Select the poselib file to load.", FileDialog.MODE_OPEN_FILE)
			if last_poselib_dir == '':
				fileSelectorPreview.current_dir = get_tree().edited_scene_root.get_node(owner.poselib_scene).filename.get_base_dir()+'/'
			else:
				fileSelectorPreview.current_dir = last_poselib_dir
			
			fileSelectorPreview.connect("file_selected", self, "_on_file_selected", [Items.LOAD], CONNECT_ONESHOT)
			fileSelectorPreview.connect("tree_exited", self, "_on_file_canceled", [], CONNECT_ONESHOT)
		Items.NEW:
			# Delete reference to current poselib
			owner.currentPoselib = null
			owner.currentPoselib = RES_PoseLibrary.new()
			owner.currentPoselib.owner_filepath = get_tree().edited_scene_root.get_node(owner.poselib_scene).filename
			var scene_name: String = owner.poselib_scene.split('/')[-1]
			if scene_name == '.':
				scene_name = get_tree().edited_scene_root.name
			$"../MenuButton"._select_scene(scene_name)
			$"../MenuButton".hint_tooltip = owner.poselib_scene+" (unsaved)"
		Items.SETUP_BONES:
#			The relationship between polygon2d and bones doesn't seem to be able to be created by code,
#			so a gross workaround is to make the user select polygon and bone relationship by hand
#			so that it works like a RemoteTransform2D.

#			This is only necessary for the previews to (roughly) reflect the pose changes,
#			Keying works fine.
			
#			Check if scene has a skeleton2D and at least a polygon2d.
#			Open SetupBonesPopup. 
			var setupBonesPopup: WindowDialog = SCN_SetupBonesPopup.instance()
			setupBonesPopup.posepalDock = owner
			add_child(setupBonesPopup)

func _on_file_selected(filepath: String, last_pressed_item: int):
#	var last_pressed_item: int = args[0]
	
	match last_pressed_item:
		Items.SAVE_AS:
			owner.save_poseData(filepath)
		Items.LOAD:
			var pure_file: String = filepath.get_file()
			var file_parts: PoolStringArray = pure_file.split('.')
			if  (file_parts.size() != 3 or file_parts[1] != 'poselib'
			or !(file_parts[2] == 'res' or file_parts[2] == 'tres')):
				print('[posepal] Loading unsuccessful. Selected file is not poselib.')
			owner.load_poseData(filepath)
			$"../MenuButton".select_poselib()

func _on_file_canceled():
	pass
