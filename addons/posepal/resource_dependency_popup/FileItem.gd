tool
extends PanelContainer

signal fixed_path (child_id)

const SCN_FileSelectorPreview: PackedScene = preload("res://addons/posepal/file_selector_preview/FileSelectorPreview.tscn")
const STY_Fixed: StyleBoxFlat = preload("res://addons/posepal/assets/uniques/StyleDependencyFileFixed.tres")
const STY_Selected: StyleBoxFlat = preload("res://addons/posepal/assets/uniques/StyleDependencyFileSelected.tres")
const STY_Broken: StyleBoxFlat = preload("res://addons/posepal/assets/uniques/StyleDependencyFileBroken.tres") 

var old_path: String = ''
var new_path: String = '' setget _set_new_path
var pure_name: String = ''
var extension: String = ''
var res_id: int = -1
enum DisplayState {
	BROKEN,
	SELECTED
	FIXED
}
var display_state: int = DisplayState.BROKEN setget _set_display_state

var fileSelectorPreview: Control
func _enter_tree() -> void:
	if old_path == '':
		return
	$HBox/OldPathLabel.text = old_path
	$HBox/PathLabel.text = ''
	$HBox/OldPathLabel.hint_tooltip = old_path
	
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
	$HBox/FileIcon.texture = editorControl.get_icon(icon_name, "EditorIcons")
#	add_stylebox_override('selected', )


func _ready() -> void:
	$HBox/OpenButton.connect("pressed", self, "_on_OpenButton_pressed")
	
func _on_OpenButton_pressed():
	fileSelectorPreview = SCN_FileSelectorPreview.instance()
	$HBox/OpenButton.add_child(fileSelectorPreview)
#	var pure_file: String = old_path.split('/', false, 100)[-1]
	var pure_file: String = old_path.trim_prefix(old_path.get_base_dir()+'/')
	print('pure_file ',pure_file,' ',extension)
	fileSelectorPreview.setup(FileDialog.ACCESS_RESOURCES, PoolStringArray([extension]),
	"* All files", "Select new path for "+pure_file)
	fileSelectorPreview.connect("file_selected", self, "_on_file_selected", [], CONNECT_ONESHOT)
	fileSelectorPreview.connect("tree_exited", self, "_on_file_canceled", [], CONNECT_ONESHOT)
	
	var d:Directory=Directory.new()
	var valid_directory: String = old_path.get_base_dir()+'/'
	for i in 100:
		valid_directory = valid_directory.trim_suffix('/')
		valid_directory = valid_directory.trim_suffix(valid_directory.split('/',false)[-1])
		if d.dir_exists(valid_directory):
			break
	fileSelectorPreview.current_dir = valid_directory
	add_stylebox_override('panel', STY_Selected)

func _on_file_selected(filepath: String):
	if filepath.get_extension() != extension:
		return
	self.new_path = filepath
	emit_signal("fixed_path", get_index())
	add_stylebox_override('panel', STY_Fixed)
		
func _on_file_canceled():
	if display_state == DisplayState.SELECTED:
		display_state = DisplayState.BROKEN

func _set_display_state(_display_state):
	display_state = _display_state
	match _display_state:
		DisplayState.BROKEN:
			add_stylebox_override('panel', STY_Broken)
		DisplayState.SELECTED:
			add_stylebox_override('panel', STY_Selected)
		DisplayState.FIXED:
			add_stylebox_override('panel', STY_Fixed)

func _set_new_path(_new_path: String):
	new_path = _new_path
	$HBox/PathLabel.text = new_path
	$HBox/PathLabel.hint_tooltip = new_path
	
	var f:File=File.new()
	if f.file_exists(new_path):
		$HBox/PathLabel.modulate = Color.white
		return
	$HBox/PathLabel.modulate = Color.red
