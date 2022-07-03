tool
extends VBoxContainer

enum PopupItems {
	EDIT
	DUPLICATE
	RENAME
	ERASE
	REORDER
	APPLY
}

var pose_id: int = -1
var pose_name: String = ""
var pose: Dictionary = {}
var poseSceneRoot: Node
var poseSkeleton: Skeleton2D
var is_being_edited: bool = false setget _set_is_being_edited
var boned_polygons: Array = []
var bones: Array = []

var filter: Array
var templatePose: Dictionary

var askNamePopup: Popup
var askIDPopup: Popup

var popupMenu: PopupMenu

var _once: bool= true

var thumbnailButton: TextureButton
var thumbnailViewport: Viewport
var label: Label
func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	thumbnailButton = $ThumbnailButton
	label = $Label
	connect( "mouse_entered", self, "_on_mouse_entered")
	connect( "mouse_exited", self, "_on_mouse_exited")
	
	thumbnailButton.connect("pressed", self, "_on_pressed", [Input.get_mouse_button_mask()])
	thumbnailButton.modulate = Color.white
	thumbnailButton.button_mask = BUTTON_LEFT | BUTTON_RIGHT
	thumbnailButton.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	
	owner = get_parent().owner
	var poselib: Resource = owner.currentPoselib
	filter = poselib.filterData[owner.poselib_filter]
	templatePose = poselib.templateData[owner.poselib_template]
	
	

var used_rect :Rect2
var used_points: PoolVector2Array
var rootPreview :Node2D
# Generates a fake scene
func generate_thumbnail():
	if !is_instance_valid(poseSceneRoot):
		return {}
	# Create thumbnail viewport or
	# clear current Scene Preview
	if !is_instance_valid(thumbnailViewport):
		thumbnailViewport = Viewport.new()
		add_child(thumbnailViewport)
		thumbnailViewport.size = Vector2(256, 256)
		thumbnailViewport.hdr = false
		thumbnailViewport.disable_3d = true
		thumbnailViewport.render_target_v_flip = true
	else:
		for child in thumbnailViewport.get_children():
			child.queue_free()
	# Add Root Preview
	var _rt: Node = _generate_previewNode(poseSceneRoot, true)
	rootPreview = _rt
	thumbnailViewport.add_child(_rt)
	if "position" in _rt:
		_rt.position = Vector2()
	
		
	if owner.poselib_filter != 'none':
		var poselib: Resource = owner.currentPoselib
		if poselib.filterData[owner.poselib_filter].size() > 0:
			_generate_preview_scene(poseSceneRoot, _rt, false, 15)
		else:
			_generate_preview_scene(poseSceneRoot, _rt, true, 15)
	else:
		_generate_preview_scene(poseSceneRoot, _rt, true, 15)
	
	var poselib: Resource = get_parent().owner.currentPoselib
	if poselib.boneRelationshipData.has('_skeleton'):
		poseSkeleton = _rt.get_node(poselib.boneRelationshipData['_skeleton'])
	_apply_fake_bones()
	
	calculate_children_used_points(_rt, 10)
	used_rect = get_used_rect(used_points)
	if "scale" in _rt:
		var new_scale_val :float= (thumbnailViewport.size.x) / max((used_rect.size.x), (used_rect.size.y)) #(thumbnailButton.rect_size*32) #/2560)#/ full_rect.position)  #* .000001
		_rt.scale = Vector2(new_scale_val, new_scale_val)
		
	var visible_offset: Vector2
	var leftover_pixels: Vector2
	if "position" in _rt:
#		Offset for all nodes in PreviewScene to fit TL corner.
		visible_offset = _rt.scale * (_rt.position - used_rect.position)
#		Number of pixels outside thumbnail.
		leftover_pixels = thumbnailViewport.size - (used_rect.size * _rt.scale)
		_rt.position = visible_offset + leftover_pixels / 2
	
#	Debug Rect
#	var visibleRect: ColorRect = ColorRect.new()
#	thumbnailViewport.add_child(visibleRect)
#	visibleRect.set_as_toplevel(true)
#	visibleRect.color = Color.white
#	visibleRect.show_behind_parent = true
#	visibleRect.rect_size = (used_rect.size) * _rt.scale
#	visibleRect.rect_position = _rt.position - visible_offset 
	
	# Screenshot it to a thumbnail,
	thumbnailButton.texture_normal = thumbnailViewport.get_texture()
	thumbnailViewport.set_clear_mode(thumbnailViewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	thumbnailViewport.set_update_mode( Viewport.UPDATE_ALWAYS)
	
#	yield(get_child(0), "tree_entered")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	var thumbnailViewportViewportTexture :ViewportTexture= thumbnailViewport.get_texture()
	var thumbnailViewportImage :Image= thumbnailViewportViewportTexture.get_data()
	thumbnailViewportImage.lock()
	
	var thumbnailImageTexture :ImageTexture= ImageTexture.new()
	thumbnailImageTexture.create_from_image(thumbnailViewportImage)
	thumbnailViewportImage.unlock()
	thumbnailButton.texture_normal = thumbnailImageTexture
	thumbnailViewport.queue_free()
	filter = []
	pose = {}
	used_points.resize(0)

func _generate_preview_scene(parent: Node = null, previewParent: Node = null, has_filtered: bool = false, iter: int = 0):
	# Loops through all of a Node's children in a maximum of %iter iterations.
	var poselib: Resource = get_parent().owner.currentPoselib
	var is_node_filtered: bool = has_filtered
	# mn - MasterNode | sn - SlaveNode
	for mn in parent.get_children(): 
		var np: String = poseSceneRoot.get_path_to(mn)
		var np_id: int = poselib.get_id_from_nodepath(np)
		var sn: Node
		if mn is Skeleton2D or mn is Bone2D:
			is_node_filtered = true
		if !is_node_filtered:
			if filter.has(np_id):
				is_node_filtered = true
		
		if is_node_filtered:
			sn = _generate_previewNode(mn)
		else:
			sn = Node2D.new()
		
		previewParent.add_child(sn)
		_generate_preview_scene(mn, sn, has_filtered, iter-1)
		if !has_filtered:
			is_node_filtered = false

func _generate_previewNode(mn: Node, is_poseroot: bool = false) -> Node:
	var poselib: Resource = get_parent().owner.currentPoselib
	var my_nodepath: String= poseSceneRoot.get_path_to(mn)
	var np_id: int = poselib.get_id_from_nodepath(my_nodepath)
	# Create dummy previewnode
	# mn - MasterNode | sn - SlaveNode
	var sn: Node
	if is_poseroot:
		sn = Sprite.new()
		sn.texture = load("res://addons/posepal/assets/icons/icon_not.png")
		sn.z_index = 1000
		sn.z_as_relative = false
		sn.self_modulate = Color()
		return sn
		
	elif mn is CanvasItem:
		match mn.get_class():
			'Sprite':
				sn = Sprite.new()
				if is_instance_valid(mn.texture):
					if mn.visible && !(owner.optionsData.ignore_scene_pose):
						sn.texture = mn.texture
						sn.offset = mn.offset
				else:
					sn.texture = load("res://addons/posepal/assets/icons/icon_not.png")
					
				if !(owner.optionsData.ignore_scene_pose):
					sn.offset = mn.offset
					sn.flip_h = mn.flip_h
					sn.flip_v = mn.flip_v
					sn.z_index = mn.z_index
			'AnimatedSprite':
				sn = AnimatedSprite.new()
				sn.frames = mn.frames
				if !(owner.optionsData.ignore_scene_pose) && is_instance_valid(mn.frames):
					sn.animation = mn.animation
					sn.frame = mn.frame
			'TextureRect':
				sn = TextureRect.new()
				sn.texture = load("res://addons/posepal/assets/icons/icon_not.png")
			'Polygon2D':
				sn = Polygon2D.new()
				var p: Polygon2D
				
				var my_path: String = poseSceneRoot.get_path_to(mn)
#				var bone_path: String
				if my_path in poselib.boneRelationshipData:
					sn.set_meta('bone_path', poselib.boneRelationshipData[my_path])
					boned_polygons.append(sn)
				sn.color = mn.color
				if is_instance_valid(mn.texture):
					sn.offset = mn.offset
					sn.skeleton = mn.skeleton
					sn.texture = mn.texture
					sn.polygon = mn.polygon
					sn.polygons = mn.polygons
					sn.uv = mn.uv
					sn.z_index = mn.z_index
					sn.rotation_degrees = 90
			'Skeleton2D':
				sn = Skeleton2D.new()
			'Bone2D':
				if !owner.optionsData.show_bones:
					sn = Bone2D.new()
					sn.rest = mn.rest
				else:
#					print('bone is line2d')
					sn = Line2D.new()
					var l:Line2D
					sn.width = 20
					sn.z_index = 1000
					bones.append(sn)
			'RemoteTransform2D':
				sn = RemoteTransform2D.new()
				sn.remote_path = mn.remote_path
			_:
				sn = Node2D.new()
		sn.modulate = mn.modulate
	else:
		sn = Node.new()
	# Load default node transform
	if mn is Node2D:
		sn.transform = mn.transform
	sn.name = mn.name
		
	if np_id in templatePose:
		var final_properties: Dictionary = templatePose[np_id].duplicate(false)
		if final_properties.has('_data'):
			final_properties.erase('_data')
		elif final_properties.has('rest'):
			final_properties.erase('rest')
		for property in final_properties.keys():
			var _copy_from_template: bool = true
			
			if pose.has(np_id):
				if pose[np_id].has(property):
					_copy_from_template = false
					
			if property in sn && _copy_from_template:
				if templatePose[np_id][property].has('val'):
					if !templatePose[np_id][property]['val'] == null:
						sn.set(property, templatePose[np_id][property]['val'])
				elif templatePose[np_id][property].has('valr'):
					sn.set(property, poselib.get_res_from_id(templatePose[np_id][property]['valr']))
	
		if mn.is_class('Polygon2D') && templatePose[np_id].has('texture'):
			sn.skeleton = templatePose[np_id]['_data']['skeleton']
			sn.polygon = templatePose[np_id]['_data']['polygon']
			sn.polygons = templatePose[np_id]['_data']['polygons']
			sn.uv = templatePose[np_id]['_data']['uv']
	
#	poselib.
	if np_id in pose:
		var final_properties: Dictionary = pose[np_id].duplicate(false)
		if final_properties.has('rest'):
			final_properties.erase('rest')
		for property in final_properties:
			if property in sn:
				if property == 'texture' or property == 'frames':
					if pose[np_id][property].has('valr'):
						if !pose[np_id][property].has('valr'):
							continue
						sn.set(property, poselib.get_res_from_id(pose[np_id][property]['valr']))
					else:
						sn.set(property, pose[np_id][property]['val'])
				else:
					sn.set(property, pose[np_id][property]['val'])
					
	if sn is Sprite:
		var s:Sprite=sn
		var can_calculate_full_rect: bool = false
		if can_calculate_full_rect:
			var _tr: Transform2D = get_node_global_transform(s)
			var rect: Rect2 = s.get_rect()
			
			used_points.append_array(PoolVector2Array([
				_tr.xform(rect.position), # TL
				_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
				_tr.xform(rect.end), # BR
				_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
			]))
	
	return sn

func get_node_global_pos(node :Node2D):
	if node == rootPreview:
		return node.position
	var parent: Node = node.get_parent()
	var global_pos = node.position
	var tr: Transform2D = node.transform
	var global_tr: Transform2D = node.transform
	
	while is_instance_valid(parent):
		if ! 'position' in parent:
			break
		
		tr = parent.get_transform()
		global_pos = tr.basis_xform(global_pos)
		parent = parent.get_parent()
	return global_pos

func get_node_global_transform(node: Node2D) -> Transform2D:
	if node == rootPreview:
		return node.transform
	var parent: Node = node.get_parent()
	var global_transform: Transform2D = node.transform
	
	while is_instance_valid(parent):
		if ! 'transform' in parent:
			break
		
		global_transform = parent.transform * parent.transform
		parent = parent.get_parent()
	return global_transform

func calculate_children_used_points(node: Node2D, iter: int):
	for child in node.get_children():
		if !child is CanvasItem:
			continue
		if !child.visible:
			continue
		if child.has_method('get_rect'):
			var rect: Rect2 = child.get_rect()
			var gl_tr: Transform2D = child.global_transform
			used_points.append_array(PoolVector2Array([
				gl_tr.xform(rect.position), # TL
				gl_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
				gl_tr.xform(rect.end), # BR
				gl_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
			]))
		calculate_children_used_points(child, iter-1)

func get_used_rect(points: PoolVector2Array) -> Rect2:
	var bound_start: Vector2 = Vector2( 10000,  10000)
	var bound_end: Vector2   = Vector2(-10000, -10000)
	
	for point in points:
		bound_start.x = min(bound_start.x, point.x)
		bound_start.y = min(bound_start.y, point.y)
		bound_end.x = max(bound_end.x, point.x)
		bound_end.y = max(bound_end.y, point.y)
	
	var _rect: Rect2
	_rect.position = bound_start
	_rect.end = bound_end
	return _rect

func _on_pressed(input_button_mask: int):
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		owner.emit_signal("pose_selected", pose_id)
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		if is_instance_valid(popupMenu):
			popupMenu.queue_free()
		popupMenu = PopupMenu.new()
		add_child(popupMenu)
		
		popupMenu.popup(Rect2(get_global_mouse_position(), Vector2(10,10)))
		popupMenu.connect("hide", self, "_on_PopupMenu_hide")
		popupMenu.connect("id_pressed", self, "_on_PopupMenu_id_selected")
		for item in PopupItems:
			popupMenu.add_item(item.to_lower())
			
		yield(get_tree(), "idle_frame")
		modulate = Color(.7,.7,1)

func _on_PopupMenu_hide():
	popupMenu.queue_free()
	thumbnailButton = $ThumbnailButton
	modulate = Color(1,1,1)

func _on_PopupMenu_id_selected(id: int):
	if !is_instance_valid(get_parent().poseCreationHBox):
		get_parent()._fix_PoseCreationHBox_ref()
	var poseCreationHBox: HBoxContainer = get_parent().poseCreationHBox
	if pose_id == -1:
		return
	
	var posePalette: GridContainer = owner.posePalette
	var poselib: Resource = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
		
	match id:
		PopupItems.APPLY:
			poseCreationHBox.apply_pose(0, poseCreationHBox.PoseType.TEMPLATE)
			poseCreationHBox.apply_pose(pose_id, 0)
		PopupItems.EDIT:
			owner.load_poseData()
			poseCreationHBox.apply_pose(0, poseCreationHBox.PoseType.TEMPLATE)
			poseCreationHBox.edit_pose(pose_id)
			
			self.is_being_edited = true
			if !poseCreationHBox.is_connected("pose_editing_canceled", self, "_on_poseCreationHBox_pose_editing_canceled"):
				poseCreationHBox.connect("pose_editing_canceled", self, "_on_poseCreationHBox_pose_editing_canceled", [], CONNECT_ONESHOT)
			else:
				print('[posepal] signal pose_editing_canceled already connected')
		PopupItems.ERASE:
			poselib.poseData[owner.poselib_template][owner.poselib_collection].remove(pose_id)
			posePalette.fill_previews()
			owner.save_poseData()
		PopupItems.RENAME:
			ask_for_name("Please insert the name for pose "+ str(pose_id))
			askNamePopup.connect('name_settled', self, '_on_name_settled')
		PopupItems.DUPLICATE:
			poselib.poseData[owner.poselib_template][owner.poselib_collection].append(poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].duplicate())
			posePalette.fill_previews()
			owner.save_poseData()
		PopupItems.REORDER:
			# Instance id selector popup
			ask_for_id("Please insert the new id for pose "+str(pose_id))
			askIDPopup.connect('id_settled', self, '_on_id_settled')
			
func _on_poseCreationHBox_pose_editing_canceled():
	self.is_being_edited = false

func _set_is_being_edited(value: bool):
	if !value:
		thumbnailButton.modulate = Color.white
		if pose_name == '':
			label.text = str(pose_id)
		else:
			label.text = str(pose_id) + ":" + pose_name
	else:
		thumbnailButton.modulate = Color(2,2,0)
		if pose_name == '':
			label.text = '(*)'+str(pose_id)
		else:
			label.text = '(*)'+str(pose_id) + ":" + pose_name
	
	is_being_edited = value

func _on_mouse_entered():
	if is_being_edited:
		return
	modulate = Color(.7,.7,1)
	
func _on_mouse_exited():
	if is_being_edited:
		return
	modulate = Color.white

func ask_for_name(title_name: String):
	if is_instance_valid(askNamePopup):
		askNamePopup.queue_free()
	askNamePopup = get_parent().SCN_AskNamePopup.instance()
	
	add_child(askNamePopup)
	askNamePopup.titlebar.title_name = title_name
	askNamePopup.label.text = "Please avoid special characters (e.g. !@*$óü~/?;| etc.)"
	return askNamePopup

func ask_for_id(title_name: String):
	var poselib: Resource = owner.currentPoselib
	if is_instance_valid(askIDPopup):
		askIDPopup.queue_free()
	askIDPopup = get_parent().SCN_AskIDPopup.instance()
	
	add_child(askIDPopup)
	askIDPopup.titlebar.title_name = title_name
	askIDPopup.max_id = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()-1
	askIDPopup.label.text = "Please select a value from 0 to " + str(askIDPopup.max_id)
	return askIDPopup

func _apply_fake_bones():
	for _p in boned_polygons:
		var polygon: Polygon2D = _p
		var bone_path: String = polygon.get_meta('bone_path')
#		print(poseSkeleton.get_node(bone_path))
		var bone: Node2D =poseSkeleton.get_node(bone_path)
		
		polygon.transform = bone.transform
		
	for _bone in bones:
		var bone: Line2D = _bone
		bone.modulate = Color(1,4,0)
		# Works somewhat.
		bone.points = [-bone.position, Vector2() ]

func _on_name_settled(new_name: String):
	var poselib: Resource = owner.currentPoselib
	if new_name == "":
		if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].erase('_name')
			
		pose_name = ""
		label.text = str(pose_id)
		hint_tooltip = label.text
		owner.save_poseData()
		return
	if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
		if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name'] == new_name:
			return
	pose_name = new_name
	poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name'] = new_name
	
	label.text = str(pose_id)+ ":"+ new_name
	hint_tooltip = label.text
	owner.save_poseData()
	
func _on_id_settled(new_id: int):
	var poselib: Resource = owner.currentPoselib
	if (new_id == pose_id or new_id < 0):
		return
	
	poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id] = (
		poselib.poseData[owner.poselib_template][owner.poselib_collection][new_id])
	poselib.poseData[owner.poselib_template][owner.poselib_collection][new_id] = pose
	
	pose_id = new_id
	if pose_name == '':
		label.text = str(pose_id)
	else:
		label.text = str(pose_id)+ ":"+ pose_name
	hint_tooltip = label.text
	owner.save_poseData()

var _debug_found_node: Node = null
func _debug_find_first_of_class(parent: Node, class_type: String):
	for child in parent.get_children():
		if child.is_class(class_type):
			_debug_found_node = child
			return
		_debug_find_first_of_class(child, class_type)
