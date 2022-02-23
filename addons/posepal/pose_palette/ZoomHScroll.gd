tool
extends HSlider


var posePalette :GridContainer
var poseContainer :ScrollContainer
func _ready() -> void:
	get_parent().get_node("ZoomIcon").texture = get_icon('Zoom', "EditorIcons")
	if get_tree().edited_scene_root == owner:
		return
	
	connect("value_changed", self, "_on_value_changed")
	posePalette = owner._get_posePalette()
	poseContainer = owner._get_posePalette().get_parent()
	
	poseContainer.connect("resized", self, "_on_PoseContainer_resized")
	_update_frame_sizes()
#	owner.get_node("VBox/AnimHBox/Button").connect('frames_filled', self, '_update_frame_sizes')

func _on_PoseContainer_resized():
	if get_tree().edited_scene_root == owner:
		return
	_update_frame_sizes()

func _on_value_changed(value :float):
	_update_frame_sizes()
	
	

func _update_frame_sizes():
	if !is_inside_tree():
		print('___________________zoom outside tree')
		return
#	posePalette = owner.posePalette
#	PoseContainer = posePalette.get_parent()
	if !is_instance_valid(posePalette):
		posePalette = owner.get_node("VSplit/TabContainer/Palette/GridContainer")
	if !is_instance_valid(poseContainer):
		poseContainer = owner.get_node("VSplit/TabContainer/Palette")
	
	var posePalette_children: Array = posePalette.get_children()
	if posePalette_children.size() == 0:
		return
	
	for posePreview in posePalette_children:
		var f :VBoxContainer= posePreview
		
		var zoomed_size :int= value * 8
		f.rect_min_size = Vector2(zoomed_size, zoomed_size + 18)
		if is_instance_valid(f.thumbnailButton):
			f.thumbnailButton.rect_min_size = f.rect_min_size
	
	
#	Still glitches sometimes, but it's better than the previous one.
#	yield(get_tree(), "idle_frame")
#	var new_columns :int= floor(owner.rect_size.x / (posePalette_children[0].rect_size.x + 8))
#	if new_columns > 0:
#		posePalette.columns =  new_columns
	_fix_columns()

func _fix_columns():
	if posePalette.get_child_count() == 0:
		return
	var new_columns :int= floor(owner.rect_size.x / (posePalette.get_child(0).rect_size.x + 8))
	if new_columns > 0:
		posePalette.columns =  new_columns
