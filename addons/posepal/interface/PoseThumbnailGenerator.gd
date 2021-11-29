tool
extends VBoxContainer

signal taken_snapshot (pose_id, texture)

# Action when pose is finished generating.
enum ThumbnailProgressionMode {
	AUTOMATIC, # Generate next pose
	MANUAL # Wait for user cluck to generate.
}
var thumbnail_progression_mode: int = ThumbnailProgressionMode.MANUAL

enum PopupItems {
	EDIT
	DUPLICATE
	RENAME
	ERASE
	REORDER
}

enum QueuedPoseData {
	POSE,
	POSE_ID,
	USED_RECT,
	USED_POINTS
}

#var pose_id: int = -1
#var pose_name: String = ""
#var pose: Dictionary = {}
var poseSceneRoot: Node
#var is_being_edited: bool = false setget _set_is_being_edited
#export var frame :StreamTexture= load("res://icon.png") setget _set_frame
var queued_poses: Array = []
var current_pose_queueid: int = -1
var is_generating: bool = false
var has_dummy_scene_created: bool = false
var dummyRoot: Node

var filterPose: Dictionary

var askNamePopup: Popup
var askIDPopup: Popup
var visibleRect: ColorRect

#var poseCreationVBox: VBoxContainer
var popupMenu: PopupMenu
var posePalDock: Control

var thumbnailButton: TextureButton
var thumbnailViewport: Viewport
var label: Label
func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	thumbnailButton = $ThumbnailButton
	label = $Label
	if thumbnail_progression_mode == ThumbnailProgressionMode.MANUAL:
#		connect( "mouse_entered", self, "_on_mouse_entered")
#		connect( "mouse_exited", self, "_on_mouse_exited")
		thumbnailButton.connect("pressed", self, "_on_pressed", [Input.get_mouse_button_mask()])
		thumbnailButton.button_mask = BUTTON_LEFT | BUTTON_RIGHT
		thumbnailButton.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	thumbnailButton.modulate = Color.white
	owner = get_parent().owner
	var poselib: Resource = owner.current_poselib
	filterPose = poselib.filterData[owner.poselib_filter]
	#print('----FILTERPPOSE-----\n',filterPose)
	
	if thumbnail_progression_mode == ThumbnailProgressionMode.AUTOMATIC:
		owner.get_node("VSplit/TabContainer").current_tab = 1

#func start_generating_queued_poses():
	

func queue_generate_thumbnail(_pose: Dictionary, _filter: Dictionary, _poseSceneRoot: Node, _pose_id: int):
	queued_poses.append([_pose, _pose_id])

#var full_rect :Rect2 # old
var used_rect_data: Array = []
var used_points_data: Array = []

#var used_rect :Rect2
#var queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS]: PoolVector2Array
var rootPreview :Node2D
# Generates a fake scene
func _generate_thumbnail(pose: Dictionary, pose_id: int, pose_pair_id: int):
	if !is_instance_valid(poseSceneRoot):
		return {}
#	print('generating thumbnail')
	is_generating = true
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
		if !has_dummy_scene_created:
			for child in thumbnailViewport.get_children():
				child.queue_free()
#	full_rect = Rect2()
#	print('_gereting tumbnail ',pose_id)
	if !has_dummy_scene_created:
		# Add Root Preview
		dummyRoot = _generate_previewNode(poseSceneRoot, true)
	#	print('root ',dummyRoot,' insidetree = ',dummyRoot.is_inside_tree())
		rootPreview= dummyRoot
		thumbnailViewport.add_child(dummyRoot)
		if "position" in dummyRoot:
			dummyRoot.position = Vector2()#-256,0)#128,0)#-64)
	#		full_rect = Rect2(Vector2(128,128), Vector2(128,128) + Vector2(2,2))
	#		full_rect = Rect2(Vector2(), Vector2(2,2))
	#		print('RT POSITIOON ',dummyRoot.position )
		# OwnerTransform
	#	if 
	
		######## NAO TESTADO SE FUNCIONA
		if owner.poselib_filter != 'none':
			_generate_preview_scene(poseSceneRoot, dummyRoot, false, 15, pose_pair_id, pose)
		else:
			_generate_preview_scene(poseSceneRoot, dummyRoot, true, 15, pose_pair_id, pose)
		has_dummy_scene_created = true
#	else:
#		_pose_previewNode(poseSceneRoot, dummyRoot, true, pose, pose_pair_id)
#		_pose_preview_scene(poseSceneRoot, dummyRoot, false, 15, pose, pose_pair_id)
#	
	calculate_children_used_points(dummyRoot, 10, pose_pair_id)
#	print(pose_pair_id, queued_poses[pose_pair_id])
	var used_points: PoolVector2Array = queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS]
	var used_rect: Rect2 = get_used_rect(queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS])
#	print('used_rect ',used_rect)
	if "scale" in dummyRoot:
		#print('fullrect difference = ',(full_rect.size - full_rect.position))
#		print('fullrect === ',full_rect.position, full_rect.size)
#		dummyRoot.scale = Vector2(.2,.2)
		#var new_scale_val :float= (thumbnailViewport.size.x) / max((full_rect.size.x-full_rect.position.x), (full_rect.size.y-full_rect.position.y)) #(thumbnailButton.rect_size*32) #/2560)#/ full_rect.position)  #* .000001
		var new_scale_val :float= (thumbnailViewport.size.x) / max((used_rect.size.x), (used_rect.size.y))*15 #(thumbnailButton.rect_size*32) #/2560)#/ full_rect.position)  #* .000001
		
		dummyRoot.scale = Vector2(new_scale_val, new_scale_val)
#		print('dummyRoot.scale ',dummyRoot.scale)
#		print('thumbn * scale === ',Vector2(128,128)*dummyRoot.scale)
#	print(thumbnailViewport.get_children())
	var visible_offset: Vector2
	var leftover_pixels: Vector2
	if "position" in dummyRoot:
#		dummyRoot.position = Vector2(128, 128)
		
#		Offset for all nodes in PreviewScene to fit TL corner.
		visible_offset = dummyRoot.scale * (dummyRoot.position - used_rect.position)#.abs()
#		Number of pixels outside thumbnail.
		leftover_pixels = thumbnailViewport.size - (used_rect.size * dummyRoot.scale)
#		visible_offset += leftover_pixels/2
#		var visible_offset: Vector2 = Vector2(full_rect.position - dummyRoot.position).abs()*dummyRoot.scale#(dummyRoot.position - full_rect.position)
#		print('VISIBLE OFFSET =',visible_offset)
#		dummyRoot.position = Vector2(0,0) + used_rect.end*dummyRoot.scale - visible_offset/2
#		dummyRoot.position = (-Vector2(128,128) +(dummyRoot.scale * (full_rect.size - full_rect.position).abs()))
#		dummyRoot.position = Vector2(128,128)#Vector2(256,256) + (dummyRoot.position*dummyRoot.scale)/visible_offset#( dummyRoot.scale * (full_rect.size- full_rect.position)/2)
#		dummyRoot.position = Vector2()+(dummyRoot.scale * Vector2(128,128)*2) + visible_offset#+visible_offset*dummyRoot.scale# + ((full_rect.size - full_rect.position).abs()*dummyRoot.scale)
		#dummyRoot.position = Vector2(80,0)+((dummyRoot.scale * full_rect.position.abs()*1.3))
#		dummyRoot.position = Vector2(0, 320) - Vector2(128, 128) * (dummyRoot.scale * (full_rect.size - full_rect.position) / 512)
#		dummyRoot.position = used_rect.position + used_rect.size/2 - visible_offset
		dummyRoot.position = visible_offset + leftover_pixels/2 #+ Vector2(thumbnailViewport.size.x * dummyRoot.scale.x,0)
#		dummyRoot.position = visible_offset + Vector2(thumbnailViewport.size.x/3,0)
#		dummyRoot.position = visible_offset #+ used_rect.position/2
#		print("_root pos ",dummyRoot.position)
	
#	Debug Rect
	if !is_instance_valid(visibleRect):
		visibleRect = ColorRect.new()
		thumbnailViewport.add_child(visibleRect)
	visibleRect.set_as_toplevel(true)
	visibleRect.color = Color(0,1,1,.2)
	visibleRect.show_behind_parent = true
	#visibleRect.rect_scale = dummyRoot.scale *2
#	visibleRect.rect_position = dummyRoot.position
	visibleRect.rect_size = (used_rect.size) * dummyRoot.scale
	visibleRect.rect_position = dummyRoot.position - visible_offset#- used_rect.size + visible_offset
#	visibleRect.rect_position = used_rect.position - visible_offset#(dummyRoot.position + visible_offset)* dummyRoot.scale#+ dummyRoot.position #/2
#	visibleRect.rect_scale = dummyRoot.scale
#	print("rectrect " ,visibleRect.rect_position, visibleRect.rect_size)
	
	# Screenshot it to a thumbnail,
#	print("thumb tex_normal ",thumbnailViewport.get_texture())
	
	thumbnailButton.texture_normal = thumbnailViewport.get_texture()
	thumbnailViewport.set_clear_mode(thumbnailViewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	thumbnailViewport.set_update_mode( Viewport.UPDATE_ALWAYS)
	print("dummy created scene ",has_dummy_scene_created)
#	print('before frameskip')
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	_pose_previewNode(poseSceneRoot, dummyRoot, true, pose, pose_pair_id)
	_pose_preview_scene(poseSceneRoot, dummyRoot, false, 15, pose, pose_pair_id)
#	print('afyer frameskip')
#	print_tree()
	var thumbnailViewportViewportTexture :ViewportTexture= thumbnailViewport.get_texture()
	var thumbnailViewportImage :Image= thumbnailViewportViewportTexture.get_data()
	thumbnailViewportImage.lock()
	
	emit_signal("taken_snapshot", pose_id, thumbnailViewport.get_texture())
#	thumbnailViewportImage.flip_y()
	var thumbnailImageTexture :ImageTexture= ImageTexture.new()
	thumbnailImageTexture.create_from_image(thumbnailViewportImage)
	thumbnailViewportImage.unlock()
#	thumbnailButton.texture_normal = thumbnailViewportTexture
	thumbnailButton.texture_normal = thumbnailImageTexture
#	emit_signal("taken_snapshot", pose_id, thumbnailButton.texture_normal)
#	Remove trash.
	thumbnailViewport.queue_free()
	filterPose = {}
	pose = {}
	is_generating = false
	
#	yield(get_tree(), "idle_frame")
#	if thumbnail_progression_mode == ThumbnailProgressionMode.AUTOMATIC:
#		generate_next_pose()

func invert_thumbnail_ver():
	pass



#func _on_PoseThumbnailGenerator_taken_snapshot(image: Image, pose_id: int):
##	print('screenshot recieved ', texture," from ",_pose_id, " my id is ", pose_id)
#	return
#	if pose_id == pose_id:
##		var imageData: Image = texture.get_data()
#		image.flip_y()
#		var thumbnailImageTexture :ImageTexture= ImageTexture.new()
#		thumbnailImageTexture.create_from_image(image)
##		thumbnailButton.texture_normal.lock()
#		thumbnailButton.texture_normal = thumbnailImageTexture;
#		print('!',pose_id,' set texture to ',image,thumbnailImageTexture)
#		thumbnailViewportImage.lock()

func _generate_preview_scene(parent: Node, previewParent: Node, has_filtered: bool, iter: int, pose_pair_id: int, pose: Dictionary):
	# Loops through all of a Node's children in a maximum of %iter iterations.
	for ch in parent.get_children():
		var _np_ch: String = poseSceneRoot.get_path_to(ch)
		var _ch: Node
		if !has_filtered:
			if filterPose.has(_np_ch):
				has_filtered = true
#				continue
		
		if has_filtered:
			_ch = _generate_previewNode(ch, false, pose)
		else:
			_ch = _generate_previewNode(ch, false, pose)
#			_ch = Node2D.new()
		previewParent.add_child(_ch)
		_generate_preview_scene(ch, _ch, has_filtered, iter-1, pose_pair_id, pose)
#	print(previewParent.get_children()[0],' globaltrans =',previewParent.get_children()[0].global_transform)


func _pose_preview_scene(parent: Node, previewParent: Node, has_filtered: bool, iter: int, pose: Dictionary, pose_pair_id: int):
	# Loops through all of a Node's children in a maximum of %iter iterations.
	for ch in parent.get_children():
		var _np_ch: String = poseSceneRoot.get_path_to(ch)
		var _ch: Node = previewParent.get_node(ch.name)
		if !has_filtered:
			if filterPose.has(_np_ch):
				has_filtered = true
#				continue
		
		if has_filtered:
#			_ch = _generate_previewNode(ch)
			_pose_previewNode(ch, _ch, false, pose, pose_pair_id)
		else:
			_pose_previewNode(ch, _ch, false, pose, pose_pair_id)
			## Make invisible
			
#			_ch = _generate_previewNode(ch)
#			_ch = Node2D.new()
		
		_pose_preview_scene(ch, _ch, has_filtered, iter-1, pose, pose_pair_id)

# Talvez poseroot seja irrelevante
func _pose_previewNode(ch: Node, _ch: Node, is_poseroot: bool, pose: Dictionary, pose_pair_id: int) -> void:
	var my_nodepath: String = poseSceneRoot.get_path_to(ch)
#	print(my_nodepath," <path> ", poseSceneRoot.get_node(my_nodepath))
	
	if is_poseroot:
		_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
		_ch.z_index = 1000
		_ch.z_as_relative = false
		_ch.self_modulate = Color()
		return
	
	# Load default node transform
	if ch is Node2D:
		_ch.transform = ch.transform
	elif ch is CanvasItem:
		match ch.get_class():
			'Sprite':
				if is_instance_valid(ch.texture):
					if ch.visible:
						_ch.texture = ch.texture
						_ch.offset = ch.offset
				else:
					_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
					
				_ch.offset = ch.offset
				_ch.flip_h = ch.flip_h
				_ch.flip_v = ch.flip_v
#				var s:Sprite
				_ch.z_index = ch.z_index
#				_ch.z_as_relative = ch.z_as_relative
			'TextureRect':
				_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
		_ch.modulate = ch.modulate
	
	# Trocado por template talvez
	if my_nodepath in filterPose:
		for property in filterPose[my_nodepath]:
			var _copy_from_filter: bool = true
			if pose.has(my_nodepath):
				if pose[my_nodepath].has(property):
					_copy_from_filter = false
			if property in _ch && _copy_from_filter:
				_ch.set(property, filterPose[my_nodepath][property]['val'])
	
	print("pose size ",pose.size())
#	print(my_nodepath,": my_nodepath in pose ",my_nodepath in pose)
	if my_nodepath in pose:
		for property in pose[my_nodepath]:
			if property in _ch:
				print(property, _ch.get(property))
				if property == 'texture':
					_ch.set('texture', pose[my_nodepath]['texture']['val'])
					#_ch.set('texture', load(pose[my_nodepath]['texture']['val']))
					
				else:
					_ch.set(property, pose[my_nodepath][property]['val'])
					
#							_ch.scale = thumbnailButton.rect_size / _ch.texture.get_size()
#				print(my_nodepath,':',property,'=',_ch.get(property))
#	if _ch is Sprite:
#		var s: Sprite = _ch
#		var can_calculate_full_rect: bool = false
#		if can_calculate_full_rect:
#			var _tr: Transform2D = get_node_global_transform(s)#s.get_transform()#.affine_inverse()
##			print(s,' lpos: ',s.position,' gpos:',get_node_global_pos(s))
##			print('origin, gpos, lpos: ',_tr.origin,', ',get_node_global_pos(s),', ',s.position)
##			var _tr :Transform2D= s.get_transform().affine_inverse()
#			var rect: Rect2 = s.get_rect()
##			print('sprite rect ',rect)
##			if is_instance_valid(s.texture):
#			queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS].append_array(PoolVector2Array([
#				_tr.xform(rect.position), # TL
#				_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
#				_tr.xform(rect.end), # BR
#				_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
#			]))
			
	
	
	return


func _generate_previewNode(ch :Node, is_poseroot: bool = false, pose: Dictionary = {}, posepair_id: int = -1) -> Node:
	var my_nodepath: String= poseSceneRoot.get_path_to(ch)
#	print('my_nodepath = ', my_nodepath)
	
#	var is_node_ignored: bool = false
	# Create dummy previewnode
	var _ch: Node
	if is_poseroot:
		_ch = Sprite.new()
		_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
		_ch.z_index = 1000
		_ch.z_as_relative = false
		_ch.self_modulate = Color()
		_ch.name = ch.name
		return _ch
	elif ch is CanvasItem:
		match ch.get_class():
			'Sprite':
				_ch = Sprite.new()
				if is_instance_valid(ch.texture):
#						_ch.texture = ch.texture
					if ch.visible:
						_ch.texture = ch.texture
						_ch.offset = ch.offset
				else:
					_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
					
				_ch.offset = ch.offset
				_ch.flip_h = ch.flip_h
				_ch.flip_v = ch.flip_v
#				var s:Sprite
				_ch.z_index = ch.z_index
#				_ch.z_as_relative = ch.z_as_relative
			'AnimatedSprite':
				_ch = AnimatedSprite.new()
			'TextureRect':
				_ch = TextureRect.new()
				_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
			'Polygon2D':
				_ch = Polygon2D.new()
			_:
				_ch = Node2D.new()
		_ch.modulate = ch.modulate
	else:
		_ch = Node.new()
	_ch.name = ch.name
	_pose_previewNode(ch, _ch, false, pose, posepair_id)
	# Load default node transform
#	if ch is Node2D:
#		_ch.transform = ch.transform
	
#		_calculate_full_rect(_ch.position, Vector2(2,2))
		
#		_ch.scale = ch.scale
#		_ch.scale = Vector2(1.1,1.1) #thumbnailViewport.size
#		print('_ch scale ',_ch.scale)
	
#	if my_nodepath in filterPose:
#		for property in filterPose[my_nodepath]:
#			var _copy_from_filter: bool = true
#			if pose.has(my_nodepath):
#				if pose[my_nodepath].has(property):
#					_copy_from_filter = false
#			if property in _ch && _copy_from_filter:
#				_ch.set(property, filterPose[my_nodepath][property]['val'])
#
#	if my_nodepath in pose:
#		for property in pose[my_nodepath]:
#			if property in _ch:
#				if property == 'texture':
#					_ch.set('texture', pose[my_nodepath]['texture']['val'])
#					#_ch.set('texture', load(pose[my_nodepath]['texture']['val']))
#
#				else:
#					_ch.set(property, pose[my_nodepath][property]['val'])
#
##							_ch.scale = thumbnailButton.rect_size / _ch.texture.get_size()
##				print(my_nodepath,':',property,'=',_ch.get(property))
#	if _ch is Sprite:
#		var s:Sprite=_ch
#		# Fallback to group's default properties.
##		if (!pose.has(my_nodepath)
##		&& !filterPose.has(my_nodepath)):
##			pass
#
#		var can_calculate_full_rect: bool = false
##		var textureSource: Sprite = ch #0=scene 1=pose
##		if 'texture' in ch:
##			can_calculate_full_rect = true
##		if my_nodepath in pose:
##			if 'texture' in pose[my_nodepath]:
##				textureSource = _ch
###				can_calculate_full_rect = true
##		elif my_nodepath in filterPose:
##			if 'texture' in filterPose[my_nodepath]:
##				can_calculate_full_rect = true
##				textureSource = _ch
#
##			_calculate_full_rect(get_node_global_pos(s), s.scale *  ch.texture.get_size(), s.offset)
##			_calculate_full_rect(get_node_global_pos(s), Vector2(4,4), s.offset)
##		yield(s, "tree_entered")
##		print('spr inside tree')
#		if can_calculate_full_rect:
##		elif ('texture' in pose[my_nodepath]
##		or 'texture' in filterPose[my_nodepath]):
##			get_node_global_transform(s)
#			var _tr: Transform2D = get_node_global_transform(s)#s.get_transform()#.affine_inverse()
##			print(s,' lpos: ',s.position,' gpos:',get_node_global_pos(s))
##			print('origin, gpos, lpos: ',_tr.origin,', ',get_node_global_pos(s),', ',s.position)
##			var _tr :Transform2D= s.get_transform().affine_inverse()
#			var rect: Rect2 = s.get_rect()
##			print('sprite rect ',rect)
##			if is_instance_valid(s.texture):
#			queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS].append_array(PoolVector2Array([
#				_tr.xform(rect.position), # TL
#				_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
#				_tr.xform(rect.end), # BR
#				_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
#			]))
#
##			print('transform =', _tr)
##			_calculate_full_rect(
##			get_node_global_pos(s),
##			_tr.xform_inv(textureSource.texture.get_size()/2),
##			Vector2())
#
##			_tr.xform(-s.offset ))#/ s.scale)
#			#_calculate_full_rect(tr.xform(s.position + gl_tr.get_origin()), s.scale * s.texture.get_size())
##			_calculate_full_rect(gl_tr.xform(s.position), s.scale * s.texture.get_size())
#			# Limit bounds to ThumbnailRect
#
##	elif _ch is Node2D:
##		var can_calculate_full_rect: bool = false
##		if my_nodepath in pose:
##			if 'texture' in pose[my_nodepath]:
##				can_calculate_full_rect = true
##		elif my_nodepath in filterPose:
##			if 'texture' in filterPose[my_nodepath]:
##				can_calculate_full_rect = true
##		if can_calculate_full_rect:
##		_calculate_full_rect(get_node_global_pos(_ch), Vector2(4,4))
#
##	if 'texture' in _ch:
##		_ch.scale = _ch.texture.get_size() / thumbnailButton.rect_size
##		print('_ch scale ',_ch.scale)
##		_ch.scale = _ch.texture.get_size() / thumbnailViewport.size
#
	return _ch

func get_node_global_pos(node :Node2D):
	if node == rootPreview:
		return node.position
	var parent :Node= node.get_parent()
	var global_pos = node.position
	var tr: Transform2D = node.transform
	var global_tr: Transform2D = node.transform
	# Maybe it just needs to calculate one time, or get root_node's xform.
#	var i: int = 0
	print(parent)
	while is_instance_valid(parent):
		if ! 'position' in parent:
			break
#		if parent == rootPreview:
#			break
		tr = parent.get_transform()
		global_pos = tr.basis_xform(global_pos)
#		global_tr.xform_inv(parent.transform)
#		current_global_pos += tr.origin#(parent.position * tr.origin)
		parent = parent.get_parent()
#		print(i)
#		i+=1
#		if is_instance_valid(parent):
#			tr = parent.transform

#		else:
#			print('________',parent,'at', parent.position,'is root')
#	print('current global pos ',current_global_pos)
#	return node.transform.xform_inv(current_global_pos)
#	print('transform global local origin',global_pos,', ',node.position)
	return global_pos#tr.xform(node.position)

func get_node_global_transform(node: Node2D) -> Transform2D:
	if node == rootPreview:
		return node.transform
	var parent :Node= node.get_parent()
	
#	var local_transform: Transform2D = node.transform
	var global_transform: Transform2D = node.transform
	while is_instance_valid(parent):
		if ! 'transform' in parent:
			break
		
		global_transform = parent.transform * parent.transform
		
		parent = parent.get_parent()
#	var parent_transform: Transform2D = node.get_parent().transform
	
	
	return global_transform

func calculate_children_used_points(node: Node2D, iter: int, pose_pair_id: int):
#	print("name in node ", 'name' in node)
#	print("node has met ",node.has_method('get_child'))
#	print("name in node ", get_rect in node)
	var used_points: Array = queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS]
	for child in node.get_children():
		if !child is CanvasItem:
			continue
		if !child.visible:
			continue
		if child.has_method('get_rect'):
			var rect: Rect2 = child.get_rect()
			var gl_tr: Transform2D = child.global_transform
#			queued_poses[pose_pair_id][QueuedPoseData.USED_POINTS].append_array(PoolVector2Array([
			used_points.append_array(PoolVector2Array([
				gl_tr.xform(rect.position), # TL
				gl_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
				gl_tr.xform(rect.end), # BR
				gl_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
			]))
		calculate_children_used_points(child, iter-1, pose_pair_id)

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

#func _calculate_full_rect(position :Vector2, size :Vector2, offset :Vector2= Vector2(), is_centered :bool= true):
#	if is_centered:
#		full_rect.position.x = min(full_rect.position.x, (position.x - size.x/2) - offset.x)
#		full_rect.end.x = max(full_rect.end.x, (position.x + size.x/2) + offset.x)
#		full_rect.position.y = min(full_rect.position.y, (position.y - size.y/2) - offset.y)
#		full_rect.end.y = max(full_rect.end.y, (position.y + size.y/2) + offset.y)
		
#		if (position.x + size.x/2) > full_rect.size.x:
#			full_rect.size.x = (position.x + size.x/2)
#		elif (position.x - size.x/2) < full_rect.position.x:
#			full_rect.position.x = (position.x - size.x/2)
#
#		if (position.y + size.y/2) > full_rect.size.y:
#			full_rect.size.y = (position.y + size.y/2)
#		elif (position.y - size.y/2) < full_rect.position.y:
#			full_rect.position.y = (position.y - size.y/2)
#	else:
#		full_rect.position.x = min(full_rect.position.x, (position.x - offset.x))
#		full_rect.size.x = max(full_rect.size.x, (position.x + size.x + offset.x))
#		full_rect.position.y = min(full_rect.position.y, (position.y - offset.y))
#		full_rect.size.y = max(full_rect.size.y, (position.y + size.y + offset.y))
#		if (position.x + size.x) > full_rect.size.x:
#			full_rect.size.x = (position.x + size.x)
#		elif (position.x - size.x) < full_rect.position.x:
#			full_rect.position.x = (position.x - size.x)
#
#		if (position.y + size.y) > full_rect.size.y:
#			full_rect.size.y = (position.y + size.y)
#		elif (position.y - size.y) < full_rect.position.y:
#			full_rect.position.y = (position.y - size.y)
		
#	if (s.position.x + p.x) > highest_point.x:
#		highest_point.x = (s.position.x + p.x)
#	if (s.position.x - p.x) < lowest_point.x:
#		lowest_point.x = (s.position.x - p.x)
		
#	if (s.position.y + p.y) > highest_point.y:
#		highest_point.y = (s.position.y + p.y)
#	if (s.position.y - p.y) < lowest_point.y:
#		lowest_point.y = (s.position.y - p.y)

func _on_pressed(input_button_mask: int):
#	Generate next pose on queue
	print(queued_poses.size())
	if thumbnail_progression_mode == ThumbnailProgressionMode.MANUAL && !is_generating:
		generate_next_pose()

func generate_next_pose():
	current_pose_queueid +=1
	if current_pose_queueid > queued_poses.size():
		return
	var pose_pair: Array = queued_poses[current_pose_queueid]
	var pose = pose_pair[0]
	var pose_id = pose_pair[1]
	queued_poses[current_pose_queueid].resize(4)
	queued_poses[current_pose_queueid][QueuedPoseData.USED_RECT] = Rect2()
	queued_poses[current_pose_queueid][QueuedPoseData.USED_POINTS] = PoolVector2Array()
	_generate_thumbnail(pose, pose_id, current_pose_queueid)

func do_automatic_thumbnail_progression():
	for i in queued_poses.size():
		var pose_pair: Array = queued_poses[i]
		var pose = pose_pair[0]
		var pose_id = pose_pair[1]
		queued_poses[i].resize(4)
		queued_poses[i][QueuedPoseData.USED_RECT] = Rect2()
		queued_poses[i][QueuedPoseData.USED_POINTS] = PoolVector2Array()
		_generate_thumbnail(pose, pose_id, i)
	print('queuedsize ',queued_poses.size())
	print_tree()
	
	queued_poses.clear()

#func generate_nex

#func _do_generation_progression():
#	match thumbnail_progression_mode:
#		ThumbnailProgressionMode.AUTOMATIC:
#			pass
#		ThumbnailProgressionMode.MANUAL:
#			pass

func begin_thumbnail_generation():
	match thumbnail_progression_mode:
		ThumbnailProgressionMode.AUTOMATIC:
			do_automatic_thumbnail_progression()
#		ThumbnailProgressionMode.MANUAL:
#			generate_next_pose()

func _on_PopupMenu_hide():
	popupMenu.queue_free()
	thumbnailButton = $ThumbnailButton
#	if !thumbnailButton.is_hovered():
	modulate = Color(1,1,1)
#	else:
#		modulate = Color(.7,.7,1)

#func _on_PopupMenu_id_selected(id: int):
#	if !is_instance_valid(get_parent().poseCreationVBox):
#		get_parent()._fix_PoseCreationVBox_ref()
#	var poseCreationVBox: VBoxContainer = get_parent().poseCreationVBox
#
#	print('pose selected ',pose_id, ':',pose_name)
#	if pose_id == -1:
#		return
##	print('$$$$ ',owner.poseData['collections'][owner.poselib_template][owner.poselib_collection][str(pose_key)])
##	var my_pose: Dictionary = owner.poseData['collections'][owner.poselib_template][owner.poselib_collection][pose_key]
#
#	var posePalette: GridContainer = owner.posePalette
#	var poselib: Resource = owner.current_poselib
#	if !is_instance_valid(poselib):
#		return
##	print('poseCreationVBox ',poseCreationVBox)
#	match id:
#		PopupItems.EDIT:
#			print('posecrea ',poseCreationVBox)
##			print('edit pose =',pose_key)
#			owner.load_poseData()
#			poseCreationVBox.edit_pose(pose_id)
#			self.is_being_edited = true
#			if !poseCreationVBox.is_connected("pose_editing_canceled", self, "_on_PoseCreationVBox_pose_editing_canceled"):
#				poseCreationVBox.connect("pose_editing_canceled", self, "_on_PoseCreationVBox_pose_editing_canceled")
#			else: print('[PosePal] signal pose_editing_canceled already connected')
##			poseCreationVBox.posegen_mode = poseCreationVBox.PoseGenMode.SAVE
##			print('poseCreationVBox posegen =',poseCreationVBox.posegen_mode)
#		PopupItems.ERASE:
#			poselib.poseData[owner.poselib_template][owner.poselib_collection].remove(pose_id)
#			posePalette.fill_previews()
#			owner.save_poseData()
#		PopupItems.RENAME:
##			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]
#			ask_for_name("Please insert the name for pose "+ str(pose_id))
#			askNamePopup.connect('name_settled', self, '_on_name_settled')
##				return
#		PopupItems.DUPLICATE:
#			# <BUG> Dictionary is referenced instead of duplicated.
##			var available_key: String = str(owner.poseData['collections'][owner.poselib_template][owner.poselib_collection].size())
#			poselib.poseData[owner.poselib_template][owner.poselib_collection].append(poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].duplicate())
#
#			posePalette.fill_previews()
#			owner.save_poseData()
##			print('pose new[',available_key,'] = ',owner.poseData['collections'][owner.poselib_template][owner.poselib_collection][available_key])
##			get_parent().owner.poseData
#		PopupItems.REORDER:
#			# Instance id selector
#			ask_for_id("Please insert the new id for pose "+str(pose_id))
#			askIDPopup.connect('id_settled', self, '_on_id_settled')
#
#func _on_PoseCreationVBox_pose_editing_canceled():
#	self.is_being_edited = false
##	if poseCreationVBox.is_connected("pose_editing_canceled", self, "_on_PoseCreationVBox_pose_editing_canceled"):
#	get_parent().poseCreationVBox.disconnect("pose_editing_canceled", self, "_on_PoseCreationVBox_pose_editing_canceled")

#func _set_is_being_edited(value: bool):
#	if !value:
#		print('not edited')
#		thumbnailButton.modulate = Color.white
#		if pose_name == '':
#			label.text = str(pose_id)
#		else:
#			label.text = str(pose_id) + ":" + pose_name
#	else:
#		print('edited')
##		self_modulate = Color(1,.2,.2)
#		thumbnailButton.modulate = Color(2,2,0)
#		if pose_name == '':
#			label.text = '(*)'+str(pose_id)
#		else:
#			label.text = '(*)'+str(pose_id) + ":" + pose_name
#
#	is_being_edited = value

#func _on_mouse_entered():
#	if is_being_edited:
#		return
#	modulate = Color(.7,.7,1)
#
#
#func _on_mouse_exited():
#	if is_being_edited:
#		return
#	modulate = Color.white

#func ask_for_name(title_name: String):
#	if is_instance_valid(askNamePopup):
#		askNamePopup.queue_free()
#	askNamePopup = get_parent().SCN_AskNamePopup.instance()
#	add_child(askNamePopup)
#	askNamePopup.titlebar.title_name = title_name
#	askNamePopup.label.text = "Please avoid special characters (e.g. !@*$óü~/?;| etc.)"
#	return askNamePopup
#
#func ask_for_id(title_name: String):
#	var poselib: Resource = owner.current_poselib
#	if is_instance_valid(askIDPopup):
#		askIDPopup.queue_free()
#	askIDPopup = get_parent().SCN_AskIDPopup.instance()
#	add_child(askIDPopup)
#	askIDPopup.titlebar.title_name = title_name
#	askIDPopup.max_id = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()-1
#	askIDPopup.label.text = "Please select a value from 0 to " + str(askIDPopup.max_id)
#	return askIDPopup

#func _on_name_settled(new_name: String):
#	var poselib: Resource = owner.current_poselib
#	# There's no need for id as it's the only option.
#	if new_name == "":
#		if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
#			poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].erase('_name')
#		pose_name = ""
#		label.text = str(pose_id)
#		hint_tooltip = label.text
#		owner.save_poseData()
#		return
#	if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id].has('_name'):
#		if poselib.poseData[owner.poselib_template][owner.poselib_collection][pose_id]['_name'] == new_name:
#			return