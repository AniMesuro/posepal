tool
extends "res://addons/posepal/interface/PropertyMenu.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var is_being_edited: bool = false setget _set_is_being_edited

func _on_pressed():
	popup = get_popup()
	popup.clear()
	popup.rect_min_size = Vector2(rect_size.x, 0)
#	popup.rect_size = popup.rect_min_size
	popup.set_as_minsize()
	
	owner.load_poseData()
	
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
	# if !poselib.is_references_valid:
	# 	return
	for node_group in poselib.filterData.keys():
		popup.add_item(node_group)
	popup.set_as_minsize()

func _on_id_selected(id :int):
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		_reset_selection()
		return
	if poselib.filterData.size() < id:
		_reset_selection()
		return
	text = poselib.filterData.keys()[id]
	icon = owner.editorControl.get_icon("Groups", "EditorIcons")
	
	owner.set("poselib_filter", poselib.filterData.keys()[id])
	owner.emit_signal("updated_reference", owner_reference)
	var posePalette :GridContainer= owner.posePalette
	posePalette.fill_previews()

func _on_PoseLibrary_updated_reference(reference :String):
	owner.load_poseData()
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		_reset_selection()
		return
	if !owner.poselib_filter in poselib.filterData.keys():
		_reset_selection()
		return

func _on_issued_forced_selection():
	if !is_instance_valid(owner.currentPoselib):
		return
	if !owner.currentPoselib.filterData.has(owner.poselib_filter):
		return
	text = owner.poselib_filter
	icon = owner.editorControl.get_icon("Groups", "EditorIcons")

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
	owner.poselib_filter = ""

func _set_is_being_edited(value: bool):
	if value:
		text = owner.poselib_filter + '(*)'
	else:
		text = owner.poselib_filter
	is_being_edited = value

func _on_poseCreationHBox_pose_editing_canceled():
	self.is_being_edited = false
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"

func _on_poseCreationHBox_pose_editing_saved():
	self.is_being_edited = false
	var poseCreationHBox: HBoxContainer = $"../../../../../../ExtraHBox/PoseCreationHBox"
