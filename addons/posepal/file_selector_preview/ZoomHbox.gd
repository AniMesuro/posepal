tool
extends HBoxContainer

var hSlider: HSlider
func _ready() -> void:
	hSlider = $HSlider
	var filePanel :Panel= $"../FilePanel"
	
	if is_instance_valid(owner.editorControl):
		$ZoomIcon.texture = owner.editorControl.get_icon("Zoom", "EditorIcons")
	
	filePanel.connect("resized", self, "_on_FilePanel_resized")
	hSlider.connect( "value_changed", self, "_on_value_changed")
	_update_FileIcon_sizes()
	
func _on_value_changed(value :float):
	_update_FileIcon_sizes()

func _on_FilePanel_resized():
	_update_FileIcon_sizes()

func _update_FileIcon_sizes():
	if !is_inside_tree():
		return
#	print('updating columns')
	var fileContainer: GridContainer = $"../FilePanel/ScrollContainer/FileContainer"
	var filePanel: Panel = $"../FilePanel"
	var hSlider: HSlider = $HSlider
	
	var fileIcons: Array = fileContainer.get_children() 
	if fileIcons == []:
		return
	
	var zoomed_size: int = hSlider.value * 8
	for fileIcon in fileIcons:
		var preview: TextureButton = fileIcon.get_node('Preview') 
		
		fileIcon.get_node('Preview').rect_min_size = Vector2(zoomed_size, zoomed_size)
	#	Still glitches sometimes, but it's better than the previous one.
	var new_columns: int = floor(filePanel.rect_size.x / (zoomed_size + 3)) # child margin 2 
	if new_columns > 0:
		fileContainer.columns =  new_columns
