
tool
extends Control

signal file_selected (filepath)

var starting_dir :String= "res://"

var current_file :String= "" setget _set_current_file
var current_dir :String setget _set_current_dir
var dir_files :PoolStringArray= PoolStringArray()
var dir_folders :PoolStringArray= PoolStringArray()

var filters :PoolStringArray= PoolStringArray()
var current_filter :String= "*" setget _set_current_filter

var editorControl :Control
func _enter_tree() -> void:
	if is_instance_valid(editorControl):
		return
	# Gets any Control node from the Editor for getting Editor icons.
	for child in get_tree().root.get_node("EditorNode").get_children():
		if child is Control:
			editorControl = child
			break

func _ready() -> void:
	current_dir = starting_dir
	_list_files()
	
	yield(get_tree(), "idle_frame")
	
	# Hacky way to get anchors to update properly.
#	rect_size = rect_size-Vector2(1,1)
	$Panel.rect_size = rect_size
	$Panel/RectHandlerContainer.handler_size = $Panel/RectHandlerContainer.handler_size
	
	

var filesystem_access :int= FileDialog.ACCESS_RESOURCES
func setup(access :int, _filters :PoolStringArray, all_filters_option :String= "* All files", dialog_title :String= "Please select a file."):
	filesystem_access = access
	filters = _filters
	$"Panel/Margin/VBox/FileHBox".all_filters_option = all_filters_option
	$"Panel/Margin/VBox/TitleBar".title_name = dialog_title

func _set_current_dir(new_dir :String):
	if current_dir.get_base_dir() == new_dir.get_base_dir():
		$"Panel/Margin/VBox/PathHBox/LineEdit".text = current_dir
		return
#	var Dir :Directory= Directory.new()
	
	if !new_dir.ends_with('/'):
		current_dir = new_dir.get_base_dir()+'/'
	else:
		current_dir = new_dir
	_list_files()
	$"Panel/Margin/VBox/PathHBox/LineEdit".text = current_dir
	self.current_file = ""

func _set_current_file(new_file :String):
	current_file = new_file
	$"Panel/Margin/VBox/FileHBox/LineEdit".text = current_file

func _set_current_filter(new_filter :String):
	if current_filter == new_filter:
		return
	
	current_filter = new_filter
	$"Panel/Margin/VBox/FilePanel/ScrollContainer/FileContainer".update_file_list()
	if current_filter == "*": # All filters
		pass

func _list_files():
	var Dir :Directory
	# Get folders and files
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
	$"Panel/Margin/VBox/FilePanel/ScrollContainer/FileContainer".update_file_list()
