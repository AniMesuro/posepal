tool
extends "res://addons/posepal/interface/PropertyMenu.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

func _on_pressed():
	popup = get_popup()
	popup.clear()
		
	owner.load_poseData()
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	if !poselib.is_references_valid:
		return
	if !poselib.poseData.has(owner.poselib_template):
		_reset_selection()
		return
	for collection in poselib.poseData[owner.poselib_template].keys():
		popup.add_item(collection)

func _on_id_selected(id :int):
	var poselib: RES_PoseLibrary = owner.current_poselib
	if poselib.poseData[owner.poselib_template].size() < id:
		_reset_selection()
		return
	text = poselib.poseData[owner.poselib_template].keys()[id]
	icon = owner.editorControl.get_icon("Folder", "EditorIcons")
	
	owner.set("poselib_collection", poselib.poseData[owner.poselib_template].keys()[id])
	owner.emit_signal("updated_reference", owner_reference)
	var posePalette :GridContainer= owner.posePalette

func _on_PoseLibrary_updated_reference(reference :String):
	owner.load_poseData()
	
	if (owner.poselib_scene != ''
	&& owner.poselib_template != ''
	&& owner.poselib_collection != ''):
		owner.fix_warning('lacking_parameters')
	
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		_reset_selection()
		return
	if !owner.poselib_template in poselib.poseData.keys():
		_reset_selection()
		return
	if !owner.poselib_collection in poselib.poseData[owner.poselib_template].keys():
		_reset_selection()
		return
	if reference == "poselib_template":
		_reset_selection()
		return

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon
	
	owner.poselib_collection = ""

func _on_issued_forced_selection():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return
	text = owner.poselib_collection
	icon = owner.editorControl.get_icon("Folder", "EditorIcons")
	var posePalette: GridContainer= owner.posePalette
	posePalette.fill_previews()
