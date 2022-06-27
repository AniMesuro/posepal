tool
extends "res://addons/posepal/interface/PropertyMoreButton.gd"

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

func is_name_valid(new_name: String):
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if (new_name == 'default') or (new_name == '') or (new_name in poselib.templateData.keys()):
		print('[posepal] Name invalid.')
		return false
	return true

var _debug_pose_broken_paths_num: int = 0
func key_template_pose():
	var animPlayer: AnimationPlayer = owner.get_selected_animationPlayer()
	if !is_instance_valid(animPlayer):
		return
	var poselib: RES_PoseLibrary = owner.currentPoselib
	
	var anim: Animation = animPlayer.get_animation(owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton.text)
	var animRoot: Node = animPlayer.get_node(animPlayer.root_node)#owner.poselib_animPlayer.root_node)
	var poseRoot: Node = get_tree().edited_scene_root.get_node(owner.poselib_scene)
	
#	var final_pose: Dictionary = poselib.templateData[owner.poselib_template].duplicate(false)
	for np_id in poselib.templateData[owner.poselib_template]:
#		var node: Node = animRoot.get_node(nodepath)
		var nodepath: String = poselib.get_nodepath_from_id(np_id)
		var node: Node = poseRoot.get_node_or_null(nodepath)
		if !is_instance_valid(node):
			_debug_pose_broken_paths_num +=1
			continue
		
		var final_properties: Dictionary = poselib.templateData[owner.poselib_template][np_id].duplicate(false)
		if final_properties.has('_data'):
			final_properties.erase('_data')
		
		var current_time: float = float(owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit.text)
#		for property in poselib.templateData[owner.poselib_template][np_id]:
		for property in final_properties.keys():
			var track_path: String = str(animRoot.get_path_to(node))+':'+property
			var tr_property: int = anim.find_track(track_path)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, track_path)
				if poselib.templateData[owner.poselib_template][np_id][property].has('upmo'):
					anim.value_track_set_update_mode(tr_property, poselib.templateData[owner.poselib_template][np_id][property]['upmo'])
				
			var key_value
			if poselib.templateData[owner.poselib_template][np_id][property].has('val'):
				key_value = poselib.templateData[owner.poselib_template][np_id][property]['val']
			elif poselib.templateData[owner.poselib_template][np_id][property].has('valr'):
				key_value = poselib.get_res_from_id(poselib.templateData[owner.poselib_template][np_id][property]['valr'])
			else:
				continue
			anim.track_insert_key(tr_property, current_time, key_value)
		
		if node.is_class('Polygon2D') && final_properties.has('texture'):
			for property in owner.PolygonDataProperties:
				var track_path: String = str(animRoot.get_path_to(node))+':'+property
				var tr_property: int = anim.find_track(track_path)
				if tr_property == -1:
					tr_property = anim.add_track(Animation.TYPE_VALUE)
					anim.track_set_path(tr_property, track_path)
					anim.value_track_set_update_mode(tr_property, anim.UPDATE_DISCRETE)
				
				var key_last: int = anim.track_find_key(tr_property, current_time - 0.01, false)
				var key_value = poselib.templateData[owner.poselib_template][np_id]['_data'][property]
				if key_last != -1:
					if anim.track_get_key_value(tr_property, key_last) == key_value:
						continue
				anim.track_insert_key(tr_property, current_time, key_value, 0.0)
				
	if _debug_pose_broken_paths_num > 0:
		owner.issue_warning("broken_nodepaths")
		print("[posepal] Couldn't finish applying pose because "+ str(_debug_pose_broken_paths_num)+
				" broken nodepaths were found.")
	_debug_pose_broken_paths_num = 0

func _on_pressed():
	popupMenu = get_popup()
	if !_is_selected_scene_valid():
		return
	popupMenu.clear()
	popupMenu.rect_min_size = Vector2(rect_size.x, 0)
	
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
	if !poselib.poseData.has(owner.poselib_template):
		popupMenu.add_item('Create', Items.CREATE)
	elif owner.poselib_template == 'default':
		popupMenu.add_item('Create', Items.CREATE)
		popupMenu.add_item('Edit', Items.EDIT)
		popupMenu.add_item('Apply', Items.APPLY)
		popupMenu.add_item('Key', Items.KEY)
	else:
		popupMenu.add_item('Edit', Items.EDIT)
		popupMenu.add_item('Create', Items.CREATE)
		popupMenu.add_item('Rename', Items.RENAME)
		popupMenu.add_item('Erase', Items.ERASE)
		popupMenu.add_item('Apply', Items.APPLY)
		popupMenu.add_item('Key', Items.KEY)

func _on_id_pressed(id: int):
	var poseCreationHBox = $"../../../../../../ExtraHBox/PoseCreationHBox"
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
	match id:
		Items.EDIT:
			owner.load_poseData()
			poseCreationHBox.edit_pose(0, poseCreationHBox.PoseType.TEMPLATE)
			var menuButton: MenuButton = $"../MenuButton"
			menuButton.is_being_edited = true
			if !poseCreationHBox.is_connected("pose_editing_canceled", menuButton, "_on_poseCreationHBox_pose_editing_canceled"):
				poseCreationHBox.connect("pose_editing_canceled", menuButton, "_on_poseCreationHBox_pose_editing_canceled", [], CONNECT_ONESHOT)
			if !poseCreationHBox.is_connected("pose_editing_saved", menuButton, "_on_poseCreationHBox_pose_editing_saved"):
				poseCreationHBox.connect("pose_editing_saved", menuButton, "_on_poseCreationHBox_pose_editing_saved", [], CONNECT_ONESHOT)
		Items.CREATE:
			ask_for_name("Please insert the name of the new template.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.RENAME:
			if owner.poselib_template == 'default':
				owner.issue_warning('cant_change_default_parameter')
				return
			ask_for_name("Please insert the new name of the " + owner.poselib_template + " collection.")
			askNamePopup.connect('name_settled', self, '_on_name_settled', [id])
		Items.ERASE:
			if owner.poselib_template == 'default':
				return
			poselib.poseData.erase(owner.poselib_template)
			poselib.templateData.erase(owner.poselib_template)
			owner.poselib_template = 'default'
			owner.emit_signal("issued_forced_selection")
			owner.save_poseData()
		Items.APPLY:
			poseCreationHBox.apply_pose(0, poseCreationHBox.PoseType.TEMPLATE)
		Items.KEY:
			key_template_pose()

func _on_name_settled(new_name: String, id: int):
	var poseCreationHBox = $"../../../../../../ExtraHBox/PoseCreationHBox"
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
	match id:
		Items.CREATE:
			if !is_name_valid(new_name):
				return
			poselib.poseData[new_name] = {'default': []}
			poselib.templateData[new_name] = {}
			owner.poselib_template = new_name
			owner.poselib_collection = 'default'
			owner.emit_signal("issued_forced_selection")
			poseCreationHBox.edit_pose(0, poseCreationHBox.PoseType.TEMPLATE)
			var menuButton: MenuButton = $"../MenuButton"
			menuButton.is_being_edited = true
			if !poseCreationHBox.is_connected("pose_editing_canceled", menuButton, "_on_poseCreationHBox_pose_editing_canceled"):
				poseCreationHBox.connect("pose_editing_canceled", menuButton, "_on_poseCreationHBox_pose_editing_canceled", [], CONNECT_ONESHOT)
			if !poseCreationHBox.is_connected("pose_editing_saved", menuButton, "_on_poseCreationHBox_pose_editing_saved"):
				poseCreationHBox.connect("pose_editing_saved", menuButton, "_on_poseCreationHBox_pose_editing_saved", [], CONNECT_ONESHOT)
				
		Items.RENAME:
			if !is_name_valid(new_name):
				return
			if owner.poselib_template == new_name:
				return
			poselib.poseData[new_name] = poselib.poseData[owner.poselib_template]
			poselib.poseData.erase(owner.poselib_template)
			poselib.templateData[new_name] = poselib.templateData[owner.poselib_template]
			poselib.templateData.erase(owner.poselib_template)
			owner.poselib_template = new_name
			
			owner.emit_signal("issued_forced_selection")
	owner.save_poseData()
