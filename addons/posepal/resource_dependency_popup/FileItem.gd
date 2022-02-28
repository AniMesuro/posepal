tool
extends HBoxContainer

const SCN_FileSelectorPreview: PackedScene = preload("res://addons/posepal/file_selector_preview/FileSelectorPreview.tscn")

var old_path: String = ''
var new_path: String = '' setget _set_new_path
var extension: String = ''

var fileSelectorPreview: Control
func _enter_tree() -> void:
	if old_path == '':
		return
	$OldPathLabel.text = old_path
	$PathLabel.text = ''
	$OldPathLabel.hint_tooltip = old_path
	
	var extension: String = old_path.get_extension()
	_get_icon_from_extension(extension)
	if File.new().file_exists(old_path):
		self.new_path = old_path

func _get_icon_from_extension(_extension: String):
	var editorControl: Control = get_parent().owner.posePalDock.pluginInstance.editorControl
	var icon_name: String = 'ResourcePreloader'
	match _extension:
		'png', 'jpg':
			icon_name = "StreamTexture"
	extension = _extension
	$FileIcon.texture = editorControl.get_icon(icon_name, "EditorIcons")
	

func _ready() -> void:
	$OpenButton.connect("pressed", self, "_on_OpenButton_pressed")

func _on_OpenButton_pressed():
	fileSelectorPreview = SCN_FileSelectorPreview.instance()
	$OpenButton.add_child(fileSelectorPreview)
#	var pure_file: String = old_path.split('/', false, 100)[-1]
	var pure_file: String = old_path.trim_prefix(old_path.get_base_dir()+'/')
	print('pure_file ',pure_file,' ',extension)
	fileSelectorPreview.setup(FileDialog.ACCESS_RESOURCES, PoolStringArray([extension]),
	"* All files", "Select new path for "+pure_file)
	fileSelectorPreview.connect("file_selected", self, "_on_file_selected")

func _on_file_selected(filepath: String):
	if filepath.get_extension() != extension:
		return
	self.new_path = filepath

func _set_new_path(_new_path: String):
	new_path = _new_path
	$PathLabel.text = new_path
	$PathLabel.hint_tooltip = new_path
