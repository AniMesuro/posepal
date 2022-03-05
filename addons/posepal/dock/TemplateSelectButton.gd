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
	if !poselib.is_references_valid:
		return
	for collection in poselib.poseData.keys():
		popup.add_item(collection)

func _on_id_selected(id :int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if poselib.poseData.size() < id:
		_reset_selection()
		return
	text = poselib.poseData.keys()[id]
	icon = owner.editorControl.get_icon("Folder", "EditorIcons")
	owner.set("poselib_template", poselib.poseData.keys()[id])
	owner.emit_signal("updated_reference", owner_reference)

func _on_PoseLibrary_updated_reference(reference :String):
	owner.load_poseData()
	
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		_reset_selection()
		return
	if !owner.poselib_template in poselib.poseData.keys():
		_reset_selection()
		return

func _on_issued_forced_selection():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.templateData.has(owner.poselib_template):
		return
	text = owner.poselib_template
	icon = owner.editorControl.get_icon("Folder", "EditorIcons")

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
	owner.poselib_template = ""

func _set_is_being_edited(value: bool):
	if value:
		text = owner.poselib_template+'(*)'
	else:
		text = owner.poselib_template
	is_being_edited = value

func _on_poseCreationHBox_pose_editing_canceled():
	self.is_being_edited = false

func _on_poseCreationHBox_pose_editing_saved():
	self.is_being_edited = false
	
