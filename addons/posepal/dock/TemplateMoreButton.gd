tool
extends "res://addons/posepal/interface/PropertyMoreButton.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

func _on_pressed():
	popupMenu = get_popup()
	if !_is_selected_scene_valid():
		return
	popupMenu.clear()
	popupMenu.rect_size = popupMenu.rect_min_size
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
#	if owner.poseData != {}:
#		if !owner.poseData.has('collections'):
#			owner.poseData['collections'] = {}
	if !poselib.poseData.has(owner.poselib_template):
		popupMenu.add_item('Create', Items.CREATE)
	elif owner.poselib_template == 'default':
		popupMenu.add_item('Create', Items.CREATE)
	else:
		popupMenu.add_item('Create',Items.CREATE)
		popupMenu.add_item('Rename',Items.RENAME)
		popupMenu.add_item('Erase',Items.ERASE)

func _on_id_pressed(id: int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
#	if owner.poseData != {}:
#		if !owner.poseData.has('collections'):
#			owner.poseData['collections'] = {}
	match id:
		Items.CREATE:
			ask_for_name("Please insert the name of the new collection.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.RENAME:
			if owner.poselib_template == 'default':
				owner.issue_warning('cant_change_default_parameter')
			ask_for_name("Please insert the new name of the " + owner.poselib_template + " collection.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.ERASE:
			if owner.poselib_template == 'default':
				return
			poselib.poseData.erase(owner.poselib_template)
			owner.poselib_template = 'default'
			owner.emit_signal("issued_forced_selection")
			owner.save_poseData()


func _on_name_settled(new_name: String, id: int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	match id:
		Items.CREATE:
			if new_name == 'default':
				return
			poselib.poseData[new_name] = {}
			owner.poselib_template = new_name
			owner.emit_signal("issued_forced_selection")
		Items.RENAME:
			if new_name == 'default':
				return
			if owner.poselib_template == new_name:
				return
			poselib.poseData[new_name] = poselib.poseData[owner.poselib_template]
			poselib.poseData.erase(owner.poselib_template)
			owner.poselib_template = new_name
			owner.emit_signal("issued_forced_selection")
	owner.save_poseData()
