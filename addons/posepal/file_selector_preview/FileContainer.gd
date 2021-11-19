tool
extends GridContainer

const SCN_FileIcon :PackedScene= preload("res://addons/rhubarb_lipsync_integration/file_selector_preview/FileIcon.tscn")
const TEX_IconFolder :StreamTexture= preload("res://addons/rhubarb_lipsync_integration/assets/icons/icon_folder.png")

var fileSelectorPreview :Control
var selectedFileIcon = null setget _set_selectedFileIcon

func _enter_tree() -> void:
	fileSelectorPreview = owner

func update_file_list():
	get_parent().scroll_vertical = 0
	#Clear children
	for child in get_children():
		child.queue_free()
	
	# Populate FileContainer with a FileIcon for each file
	for folder in owner.dir_folders:
		# Ignore folder if folder special directory
		if folder == '.' or folder == '..':
			continue
			
		var fileIcon :VBoxContainer= SCN_FileIcon.instance()
		add_child(fileIcon)
		fileIcon.setup(folder, fileIcon.TYPE.folder)
		fileIcon.connect("folder_selected", self, "_on_folder_selected") 
		
	for file in owner.dir_files:
		if owner.current_filter != "*":
			if !file.get_extension() == owner.current_filter:
				continue
		else:
			if !file.get_extension() in owner.filters:
				continue
			
		var fileIcon :VBoxContainer= SCN_FileIcon.instance()
		add_child(fileIcon)
		fileIcon.setup(file, fileIcon.TYPE.file)
		fileIcon.connect("file_selected", self, "_on_file_selected")
	$"../../../ZoomHbox"._update_FileIcon_sizes()

func _on_file_selected(file_name :String):
	owner.current_file = file_name
	for icon in get_children():
		if icon.file_name == file_name:
			self.selectedFileIcon = icon

func _set_selectedFileIcon(new_fileIcon :VBoxContainer):
	if is_instance_valid(selectedFileIcon):
		selectedFileIcon.selected = false
				
	new_fileIcon.selected = true
	selectedFileIcon = new_fileIcon

func _on_folder_selected(file_name :String):
	owner.current_dir = owner.current_dir + file_name + "/"
	
