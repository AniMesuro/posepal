
tool
extends WindowDialog

signal file_selected (filepath)

var starting_dir: String= "res://"
var current_file: String = "" setget _set_current_file
var current_dir: String setget _set_current_dir
var dir_files: PoolStringArray = PoolStringArray()
var dir_folders: PoolStringArray = PoolStringArray()

var filters: PoolStringArray = PoolStringArray()
var current_filter: String = "*" setget _set_current_filter
var mode: int

var editorControl :Control
func _enter_tree() -> void:
	visible = true
	if get_tree().edited_scene_root == self:
		return
	if is_instance_valid(editorControl):
		return
	popup_centered()
	# Gets any Control node from the Editor for getting Editor icons.
	for child in get_tree().root.get_node("EditorNode").get_children():
		if child is Control:
			editorControl = child
			break

func _ready() -> void:
	current_dir = starting_dir

var filesystem_access: int = FileDialog.ACCESS_RESOURCES
func setup(access: int, _filters: PoolStringArray, all_filters_option: String = "* All files",
dialog_title: String = "Please select a file.", _mode: int = FileDialog.MODE_OPEN_FILE):
	filesystem_access = access
	filters = _filters
	mode = _mode
	
	$"Margin/VBox/FileHBox".all_filters_option = all_filters_option
	$"Margin/VBox/TitleBar".title_name = dialog_title
	$"Margin/VBox/FileHBox".update_extensions()
	_list_directory()

#func set_default_file(name: String):
#	$"Margin/VBox/FileHBox/LineEdit".text = name

func _set_current_dir(new_dir :String):
	if current_dir.get_base_dir() == new_dir.get_base_dir():
		$"Margin/VBox/PathHBox/LineEdit".text = current_dir
		return
	
	if !new_dir.ends_with('/'):
		current_dir = new_dir+'/'
#		current_dir = new_dir.get_base_dir()+'/'
	else:
		current_dir = new_dir
		
	_list_directory()
	$"Margin/VBox/PathHBox/LineEdit".text = current_dir
	self.current_file = ""

func _set_current_file(new_file :String):
	current_file = new_file
	
	$"Margin/VBox/FileHBox/LineEdit".text = current_file

func _set_current_filter(new_filter :String):
	if current_filter == new_filter:
		return
	
	current_filter = new_filter
	$"Margin/VBox/FilePanel/ScrollContainer/FileContainer".update_file_list()
	$"Margin/VBox/FileHBox/ExtensionMenu".text = current_filter
	
	if current_filter == '*':
		$"Margin/VBox/FileHBox/ExtensionMenu".text = $"Margin/VBox/FileHBox".all_filters_option
		return
	if current_file.get_extension() != current_filter:
		if mode == FileDialog.MODE_SAVE_FILE:
#			print('basename ',current_file.get_basename())
			
			self.current_file = current_file.get_basename()+'.'+current_filter
		elif mode == FileDialog.MODE_OPEN_FILE:
			self.current_file = ''
	

func _list_directory():
	var Dir :Directory
	dir_files = []
	dir_folders = []
	
	Dir = Directory.new()
	if Dir.open(current_dir) == OK:
		Dir.list_dir_begin()
		var file_name = Dir.get_next()
		while file_name != "":
			if !Dir.current_is_dir():
				dir_files.append(file_name)
			else:
				dir_folders.append(file_name)
			file_name = Dir.get_next()
	$"Margin/VBox/FilePanel/ScrollContainer/FileContainer".update_file_list()
	
