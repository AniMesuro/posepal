tool
extends VBoxContainer

const SCN_FileItem: PackedScene = preload("res://addons/posepal/resource_dependency_popup/FileItem.tscn")

func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		return
	fill_files()

func fill_files():
	var old_paths = owner.old_paths
	for path in old_paths:
		var item: HBoxContainer = SCN_FileItem.instance()
		item.old_path = path
		add_child(item)
