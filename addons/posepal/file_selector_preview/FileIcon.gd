tool
extends VBoxContainer

signal file_selected (filepath)
signal folder_selected (filepath)

enum TYPE {
	file,
	folder
}
var my_type :int
var selected :bool= false setget _set_selected
var file_name :String= "icon.png"

func _ready() -> void:
	var preview :TextureButton= $Preview
	preview.connect("pressed", self, "_on_Preview_pressed")

func setup(_file_name :String, _type :int= TYPE.file):
	var label :Label= $Label
	
	file_name = _file_name
	label.text = file_name
	my_type = _type
	# files beginning with . are not extensions
	var preview :TextureButton= $Preview
	if my_type == TYPE.folder:
		preview.texture_normal = get_parent().TEX_IconFolder
		return
		
	var eCtrl :Control = get_parent().fileSelectorPreview.editorControl
	match file_name.get_extension():
		'png','jpg','jpeg':
			preview.texture_normal = load(get_parent().fileSelectorPreview.current_dir+ file_name)
		'gd':
			if is_instance_valid(eCtrl):
				preview.texture_normal = eCtrl.get_icon("GDScript", "EditorIcons")
		'tscn', 'scn':
			if is_instance_valid(eCtrl):
				preview.texture_normal = eCtrl.get_icon("PackedScene", "EditorIcons")
		'txt':
			if is_instance_valid(eCtrl):
				preview.texture_normal = eCtrl.get_icon("RichTextLabel", "EditorIcons")
		'ini', 'cfg':
			if is_instance_valid(eCtrl):
				preview.texture_normal = eCtrl.get_icon("TextFile", "EditorIcons")
		_:
			if file_name.get_extension() == "":
				return
			if is_instance_valid(eCtrl):
				preview.texture_normal = eCtrl.get_icon("File", "EditorIcons")
				
#			if is_instance_valid(eCtrl):
#				preview.texture_normal = eCtrl.

func _set_selected(value :bool):
	if selected == value:
		return
	
	if value:
		modulate = Color(0.5,0.5,2, 1)
	else:
		modulate = Color.white
	selected = value

func _on_Preview_pressed():
	if my_type == TYPE.file:
		emit_signal("file_selected", file_name)
	elif my_type == TYPE.folder:
		emit_signal("folder_selected", file_name)
