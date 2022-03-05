tool
extends "res://addons/posepal/interface/PropertyMoreButton.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

func _on_pressed():
	popupMenu = get_popup()
	if !_is_selected_scene_valid():
		return
	popupMenu.clear()
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		popupMenu.add_item('Create', Items.CREATE)
	else:
		popupMenu.add_item('Create',Items.CREATE)
		popupMenu.add_item('Rename',Items.RENAME)
		popupMenu.add_item('Erase',Items.ERASE)

func _on_id_pressed(id: int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	match id:
		Items.CREATE:
			ask_for_name("Please insert the name of the new subcollection.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.RENAME:
			if owner.poselib_collection == 'default':
				return
			ask_for_name("Please insert the new name of the" + owner.poselib_collection + " subcollection.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.ERASE:
			# Needs confirmation for the future.
			if owner.poselib_collection == 'default':
				return
			poselib.poseData[owner.poselib_template].erase(owner.poselib_collection)
			owner.emit_signal("issued_forced_selection")
			owner.save_poseData()

func _on_name_settled(new_name: String, id: int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	match id:
		Items.CREATE:
			if !is_name_valid(new_name):
				return
			poselib.poseData[owner.poselib_template][new_name] = []
			owner.poselib_collection = new_name
			owner.emit_signal("issued_forced_selection")
		Items.RENAME:
			if !is_name_valid(new_name):
				return
			if owner.poselib_collection == new_name:
				return
			poselib.poseData[owner.poselib_template][new_name] = poselib.poseData[owner.poselib_template][owner.poselib_collection]
			poselib.poseData[owner.poselib_template].erase(owner.poselib_collection)
			owner.poselib_collection = new_name
			owner.emit_signal("issued_forced_selection")
	owner.save_poseData()

func is_name_valid(new_name: String) -> bool:
	var poselib: RES_PoseLibrary = owner.current_poselib
	if ((new_name == 'default' && owner.poselib_template == "default")
	or (new_name == '') or (new_name in poselib.poseData[owner.poselib_template])):
		return false
	return true
