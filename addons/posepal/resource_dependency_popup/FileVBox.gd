tool
extends VBoxContainer



const SCN_FileItem: PackedScene = preload("res://addons/posepal/resource_dependency_popup/FileItem.tscn")
var children_as_dict: Dictionary = {}

func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		return
	fill_files()

func fill_files():
	var old_paths = owner.old_paths
	var poselib: Resource = owner.poselib
	for k in poselib.resourceReferences.keys():
		var path: String = poselib.resourceReferences[k][0]
		var item: HBoxContainer = SCN_FileItem.instance()
		item.old_path = path
		item.res_id = k
		item.pure_name = path.split('/',false)[-1]
		children_as_dict[k] = item
		add_child(item)
		item.connect('fixed_path', self, '_on_item_fixed_path')


func _on_item_fixed_path(ch: int):
	$"../../../GuessButton".disabled = false
	
	for child in get_children():
		if child.is_connected('fixed_path', self, '_on_item_fixed_path'):
			child.disconnect('fixed_path', self, '_on_item_fixed_path')
