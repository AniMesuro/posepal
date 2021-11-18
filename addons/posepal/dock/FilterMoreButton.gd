tool
extends "res://addons/posepal/interface/PropertyMoreButton.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")
#var poseCreationVBox: VBoxContainer
#func _ready() -> void:
#	var poseCreationVBox = $"../../../ExtraHBox/PoseCreationVBox"#owner.get_node("VBox/ExtraHBox/PoseCreationVBox")
	

func _on_pressed():
	popupMenu = get_popup()
	if !_is_selected_scene_valid():
		return
	popupMenu.clear()
#	popupMenu.rect_size = popupMenu.rect_min_size
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
#	if owner.poseData != {}:
#	if !owner.poseData.has('groups'):
#		owner.poseData['groups'] = {}
	if !poselib.filterData.has(owner.poselib_filter):
		popupMenu.add_item('Create', Items.CREATE)
	elif owner.poselib_template == 'none': # Not recommended, but user can edit properties of a key (NOT NODES)
		popupMenu.add_item('Edit', Items.EDIT)
		popupMenu.add_item('Create', Items.CREATE)
	else:
		popupMenu.add_item('Edit', Items.EDIT)
		popupMenu.add_item('Create',Items.CREATE)
		popupMenu.add_item('Rename',Items.RENAME)
		popupMenu.add_item('Erase',Items.ERASE)

func _on_id_pressed(id: int):
	var poseCreationVBox = owner.get_node("VSplit/ExtraHBox/PoseCreationVBox")
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
#	if owner.poseData != {}:
#		if !owner.poseData.has('groups'):
#			owner.poseData['groups'] = {}
	match id:
		Items.EDIT:
			# Edit Filter pose
			owner.load_poseData()
			poseCreationVBox.edit_pose(0, poseCreationVBox.PoseType.FILTER)
			var menuButton: MenuButton = $"../MenuButton"
			menuButton.is_being_edited = true
			if !poseCreationVBox.is_connected("pose_editing_canceled", menuButton, "_on_PoseCreationVBox_pose_editing_canceled"):
				poseCreationVBox.connect("pose_editing_canceled", menuButton, "_on_PoseCreationVBox_pose_editing_canceled")
		Items.CREATE:
			ask_for_name("Please insert the name for the new filter pose.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.RENAME:
			if owner.poselib_filter == 'none':
				return
			ask_for_name("Please insert the new name for the "+ owner.poselib_filter +" filter pose.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.ERASE:
			if owner.poselib_filter == 'none':
				return
			poselib.filterData.erase(owner.poselib_filter)
			owner.poselib_filter = 'none'
			owner.save_poseData()
			owner.emit_signal("issued_forced_selection")


func _on_name_settled(new_name: String, id: int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	match id:
		Items.CREATE:
			if new_name == 'none':
				return
			poselib.filterData[new_name] = {}
			
			owner.poselib_filter = new_name
			owner.emit_signal("issued_forced_selection")
		Items.RENAME:
			if new_name == 'none':
				return
			if owner.poselib_filter == new_name:
				return
			poselib.filterData[new_name] = poselib.filterData[owner.poselib_filter]
			poselib.filterData.erase(owner.poselib_filter)
			owner.poselib_filter = new_name
			owner.emit_signal("issued_forced_selection")
	owner.save_poseData()
