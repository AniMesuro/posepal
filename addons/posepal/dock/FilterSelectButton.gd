tool
extends "res://addons/posepal/interface/PropertyMenu.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var is_being_edited: bool = false setget _set_is_being_edited

func _on_pressed():
	popup = get_popup()
	popup.clear()
	
	owner.load_poseData()
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
#	if owner.poseData != {}:
#		if !owner.poseData.has('groups'):
#			_reset_selection()
#			return
#		print('PoseData["groups"] = ',owner.poseData['groups'])
	for node_group in poselib.filterData.keys():
#	for node_group in owner.poseData['groups'].keys():
		popup.add_item(node_group)
	popup.rect_size = popup.rect_min_size

func _on_id_selected(id :int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		_reset_selection()
		return
	if poselib.filterData.size() < id:
#	if owner.poseData['groups'].size() < id:
		_reset_selection()
		return
	text = poselib.filterData.keys()[id]
#	text = owner.poseData['groups'].keys()[id]
	icon = owner.editorControl.get_icon("Groups", "EditorIcons")
	owner.set("poselib_filter", poselib.filterData.keys()[id])
#	owner.set("poselib_template", owner.poseData['groups'].keys()[id])
	
	owner.emit_signal("updated_reference", owner_reference)
	var posePalette :GridContainer= owner.posePalette#get_node("VBox/PoseContainer/PosePalette")
	posePalette.fill_previews()

func _on_PoseLibrary_updated_reference(reference :String):
	owner.load_poseData()
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
#	if owner.poseData == {}:
		_reset_selection()
		return
#	if !owner.poseData.has('groups'):
#		_reset_selection()
#		return
	if !owner.poselib_filter in poselib.filterData.keys():
		_reset_selection()
		return

func _on_issued_forced_selection():
	if !is_instance_valid(owner.current_poselib):
#	if owner.poseData == {}:
		return
#	if !owner.poseData.has('groups'):
#		return
	if !owner.current_poselib.filterData.has(owner.poselib_filter):
#	if !owner.poseData['groups'].has(owner.poselib_template):
		return
	text = owner.poselib_filter
#	text = owner.poselib_template
	icon = owner.editorControl.get_icon("Groups", "EditorIcons")

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
#	owner.poselib_template = ""
	owner.poselib_filter = ""

func _set_is_being_edited(value: bool):
	pass

func _on_PoseCreationVBox_pose_editing_canceled():
	self.is_being_edited = false
