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
var np_id: int = -1
var poseRoot: Node
enum DisplayState {
	BROKEN,
	SELECTED
	FIXED
}
var display_state: int = DisplayState.BROKEN setget _set_display_state

var fileSelectorPreview: Control

const SCN_NodepathPopup: PackedScene = preload("res://addons/posepal/nodepath_reference_popup/NodepathPopup.tscn")

func _ready() -> void:
	var _fakePlugin: EditorPlugin = EditorPlugin.new()
	$"HBox/NodeIcon".texture = _fakePlugin.get_editor_interface().get_base_control().get_icon("NodePath", "EditorIcons")
	$"HBox/SelectButton".texture_normal = _fakePlugin.get_editor_interface().get_base_control().get_icon("PopupMenu", "EditorIcons")
	$"HBox/SelectButton".connect("pressed", self, "_on_SelectButton_pressed")
	owner = get_parent().owner
	add_stylebox_override('panel', STY_Broken)
	
func _on_SelectButton_pressed():
#	var nodeItem: HBoxContainer = SCN_NodeItem.instance()
#	add_child(nodeItem)
	var nodepathPopup: WindowDialog = SCN_NodepathPopup.instance()
	nodepathPopup.posepalDock = owner.posepalDock
	add_child(nodepathPopup)
	nodepathPopup.connect("nodepath_selected", self, "_on_nodepath_selected")
	nodepathPopup.connect("tree_exited", self, "_on_nodepath_canceled")
	add_stylebox_override('panel', STY_Selected)

func _enter_tree() -> void:
	if old_path == '':
		return
	
	if old_path != '.':
		$HBox/OldPathLabel.text = old_path
	else:
		$HBox/OldPathLabel.text = pure_name
	$HBox/PathLabel.text = ''
	$HBox/OldPathLabel.hint_tooltip = old_path
	
#	_get_icon_from_extension(extension)
	# Nodepath valid
	get_parent()
	if File.new().file_exists(old_path):
		self.new_path = old_path

#func _get_icon_from_extension():
#	var editorControl: Control = get_parent().owner.posepalDock.pluginInstance.editorControl
#	var icon_name: String = 'ResourcePreloader'
#	match _extension:
#		'png', 'jpg':
#			icon_name = "StreamTexture"
#	extension = _extension
#	$HBox/FileIcon.texture = editorControl.get_icon(icon_name, "EditorIcons")

	
func _on_OpenButton_pressed():
	fileSelectorPreview = SCN_FileSelectorPreview.instance()
	$HBox/OpenButton.add_child(fileSelectorPreview)
	var pure_nodepath: String = old_path.trim_prefix(old_path.get_base_dir()+'/')
	fileSelectorPreview.setup(FileDialog.ACCESS_RESOURCES, PoolStringArray([extension]),
	"* All files", "Select new path for "+pure_nodepath, FileDialog.MODE_OPEN_FILE)
	fileSelectorPreview.connect("file_selected", self, "_on_nodepath_selected", [], CONNECT_ONESHOT)
	fileSelectorPreview.connect("tree_exited", self, "_on_nodepath_canceled", [], CONNECT_ONESHOT)
	
	var d:Directory=Directory.new()
	var valid_directory: String = old_path.get_base_dir()+'/'
	for i in 100:
		valid_directory = valid_directory.trim_suffix('/')
		valid_directory = valid_directory.trim_suffix(valid_directory.split('/',false)[-1])
		if d.dir_exists(valid_directory):
			break
	fileSelectorPreview.current_dir = valid_directory
	add_stylebox_override('panel', STY_Selected)

func _on_nodepath_selected(nodepath: String):
#	if filepath.get_extension() != extension:
#		return
	self.new_path = nodepath
	emit_signal("fixed_path", get_index())
	self.display_state = DisplayState.FIXED
		
func _on_nodepath_canceled():
	validate_new_path()
	
#	if display_state == DisplayState.SELECTED:
#		display_state = DisplayState.BROKEN

func validate_new_path():
	if poseRoot.get_node_or_null(new_path):
		display_state = DisplayState.FIXED
	else:
		display_state = DisplayState.BROKEN

func _set_display_state(_display_state):
	display_state = _display_state
	match _display_state:
		DisplayState.BROKEN:
			add_stylebox_override('panel', STY_Broken)
			$HBox/PathLabel.modulate = Color.white
		DisplayState.SELECTED:
			add_stylebox_override('panel', STY_Selected)
			$HBox/PathLabel.modulate = Color.green
		DisplayState.FIXED:
			add_stylebox_override('panel', STY_Fixed)
			$HBox/PathLabel.modulate = Color.yellow

func _set_new_path(_new_path: String):
	new_path = _new_path
	$HBox/PathLabel.text = new_path
	$HBox/PathLabel.hint_tooltip = new_path
	
#	var f:File=File.new()
#	if f.file_exists(new_path):
#		$HBox/PathLabel.modulate = Color.white
#		return
	

