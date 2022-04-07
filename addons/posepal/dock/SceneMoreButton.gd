tool
extends MenuButton

const SCN_FileSelectorPreview: PackedScene = preload("res://addons/posepal/file_selector_preview/FileSelectorPreview.tscn")
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")


enum Items {
#	NEW,
	SAVE,
	SAVE_AS,
#	LOAD,
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
	popupMenu = get_popup()
#	if !_is_selected_scene_valid():
#		return
	popupMenu.clear()
	popupMenu.rect_min_size = Vector2(rect_size.x, 0)
	
	var poselib: RES_PoseLibrary = owner.current_poselib
	if is_instance_valid(poselib):
#		popupMenu.add_item('New', Items.NEW)
#		popupMenu.add_item('Load', Items.LOAD)
		popupMenu.add_item('Save', Items.SAVE)
		popupMenu.add_item('Save as', Items.SAVE_AS)
#	else:
#		popupMenu.add_item('Load', Items.LOAD)

func _on_id_pressed(id: int):
	match id:
		Items.SAVE:
			owner.save_poseData()
		Items.SAVE_AS:
			var pure_old_file: String = owner.current_poselib.resource_path.get_file().split('.')[0]
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
				fileSelectorPreview.current_dir = owner.current_poselib.owner_filepath.get_base_dir() + '/'
			fileSelectorPreview.current_file = pure_file +'.poselib.'+ poselib_extension
			fileSelectorPreview.current_filter = poselib_extension
			
			fileSelectorPreview.connect("file_selected", self, "_on_file_selected", [Items.SAVE_AS], CONNECT_ONESHOT)
			fileSelectorPreview.connect("tree_exited", self, "_on_file_canceled", [], CONNECT_ONESHOT)
#		Items.LOAD:
#			var fileSelectorPreview = SCN_FileSelectorPreview.instance()
#			add_child(fileSelectorPreview)
#
#			fileSelectorPreview.connect("file_selected", self, "_on_file_selected", [Items.LOAD], CONNECT_ONESHOT)
#			fileSelectorPreview.connect("tree_exited", self, "_on_file_canceled", [], CONNECT_ONESHOT)

func _on_file_selected(filepath: String, last_pressed_item: int):
#	var last_pressed_item: int = args[0]
	
	match last_pressed_item:
		Items.SAVE_AS:
			owner.save_poseData(filepath)

func _on_file_canceled():
	pass
