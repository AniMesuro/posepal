tool
extends Viewport

signal taken_snapshot (texture)

var used_rect :Rect2
var used_points: PoolVector2Array

var filterPose: Dictionary
var pose: Dictionary = {}
var poseSceneRoot: Node
var rootPreview: Node2D

var posePalDock: Control

func generate_thumbnail(_pose: Dictionary, _filterPose: Dictionary, _poseSceneRoot: Node, pose_id: int = -1):
	print('generating ',pose_id)
	if !is_instance_valid(_poseSceneRoot):
		return {}
#	print('generating thumbnail')
#	full_rect = Rect2()
	pose = _pose
	filterPose = _filterPose
	poseSceneRoot = _poseSceneRoot
	
	
	
	# Add Root Preview
	var _rt :Node= _generate_previewNode(poseSceneRoot, true)
	
#	print('root ',_rt,' insidetree = ',_rt.is_inside_tree())
	rootPreview= _rt
	add_child(_rt)
	if "position" in _rt:
		_rt.position = Vector2()#-256,0)#128,0)#-64)
#		full_rect = Rect2(Vector2(128,128), Vector2(128,128) + Vector2(2,2))
#		full_rect = Rect2(Vector2(), Vector2(2,2))
#		print('RT POSITIOON ',_rt.position )
	# OwnerDockTransform
#	if 
	
	######## NAO TESTADO SE FUNCIONA
	if posePalDock.poselib_filter != 'none':
		_generate_preview_scene(poseSceneRoot, _rt, false, 15)
	else:
		_generate_preview_scene(poseSceneRoot, _rt, true, 15)
	print(pose_id, ' aaa')
#	print_tree()
	
	calculate_children_used_points(_rt, 10)
	var used_rect: Rect2 = get_used_rect(used_points)
#	print('used_rect ',used_rect)
	if "scale" in _rt:
		#print('fullrect difference = ',(full_rect.size - full_rect.position))
#		print('fullrect === ',full_rect.position, full_rect.size)
#		_rt.scale = Vector2(.2,.2)
		#var new_scale_val :float= (size.x) / max((full_rect.size.x-full_rect.position.x), (full_rect.size.y-full_rect.position.y)) #(thumbnailButton.rect_size*32) #/2560)#/ full_rect.position)  #* .000001
		var new_scale_val :float= (size.x) / max((used_rect.size.x), (used_rect.size.y)) #(thumbnailButton.rect_size*32) #/2560)#/ full_rect.position)  #* .000001
		
		_rt.scale = Vector2(new_scale_val, new_scale_val)
#		print('_rt.scale ',_rt.scale)
#		print('thumbn * scale === ',Vector2(128,128)*_rt.scale)
#	print(get_children())
	var visible_offset: Vector2
	var leftover_pixels: Vector2
	if "position" in _rt:
#		_rt.position = Vector2(128, 128)
		
#		Offset for all nodes in PreviewScene to fit TL corner.
		visible_offset = _rt.scale * (_rt.position - used_rect.position)#.abs()
#		Number of pixels outside thumbnail.
		leftover_pixels = size - (used_rect.size * _rt.scale)
#		visible_offset += leftover_pixels/2
#		var visible_offset: Vector2 = Vector2(full_rect.position - _rt.position).abs()*_rt.scale#(_rt.position - full_rect.position)
#		print('VISIBLE OFFSET =',visible_offset)
#		_rt.position = Vector2(0,0) + used_rect.end*_rt.scale - visible_offset/2
#		_rt.position = (-Vector2(128,128) +(_rt.scale * (full_rect.size - full_rect.position).abs()))
#		_rt.position = Vector2(128,128)#Vector2(256,256) + (_rt.position*_rt.scale)/visible_offset#( _rt.scale * (full_rect.size- full_rect.position)/2)
#		_rt.position = Vector2()+(_rt.scale * Vector2(128,128)*2) + visible_offset#+visible_offset*_rt.scale# + ((full_rect.size - full_rect.position).abs()*_rt.scale)
		#_rt.position = Vector2(80,0)+((_rt.scale * full_rect.position.abs()*1.3))
#		_rt.position = Vector2(0, 320) - Vector2(128, 128) * (_rt.scale * (full_rect.size - full_rect.position) / 512)
#		_rt.position = used_rect.position + used_rect.size/2 - visible_offset
		_rt.position = visible_offset + leftover_pixels/2 #+ Vector2(size.x * _rt.scale.x,0)
#		_rt.position = visible_offset + Vector2(size.x/3,0)
#		_rt.position = visible_offset #+ used_rect.position/2
#		print("_root pos ",_rt.position)
	
#	Debug Rect
	var visibleRect: ColorRect = ColorRect.new()
	add_child(visibleRect)
	visibleRect.set_as_toplevel(true)
	visibleRect.color = Color(0,1,1,.2)
	visibleRect.show_behind_parent = true
	#visibleRect.rect_scale = _rt.scale *2
#	visibleRect.rect_position = _rt.position
	visibleRect.rect_size = (used_rect.size) * _rt.scale
	visibleRect.rect_position = _rt.position - visible_offset#- used_rect.size + visible_offset
#	visibleRect.rect_position = used_rect.position - visible_offset#(_rt.position + visible_offset)* _rt.scale#+ _rt.position #/2
#	visibleRect.rect_scale = _rt.scale
#	print("rectrect " ,visibleRect.rect_position, visibleRect.rect_size)
	
	# Screenshot it to a thumbnail,
	print(get_texture())
	var viewportImage: Image = get_texture().get_data()
	print("image", viewportImage)
#	var viewportImage: Image = viewportTexture.get_data()
#	viewportImage.lock()
	emit_signal("taken_snapshot", viewportImage, pose_id)
##	thumbnailButton.texture_normal = get_texture()
#	set_clear_mode(CLEAR_MODE_ONLY_NEXT_FRAME)
#	set_update_mode( Viewport.UPDATE_ALWAYS)
#	yield(get_tree(), "idle_frame")
#	yield(get_tree(), "idle_frame")
#
#	var thumbnailViewportViewportTexture: ViewportTexture = get_texture()
#	var thumbnailViewportImage: Image = thumbnailViewportViewportTexture.get_data()
#	thumbnailViewportImage.lock()
#
#
##	thumbnailViewportImage.flip_y()
#	var thumbnailImageTexture: ImageTexture = ImageTexture.new()
#	thumbnailImageTexture.create_from_image(thumbnailViewportImage)
#	thumbnailViewportImage.unlock()
##	thumbnailButton.texture_normal = thumbnailViewportTexture
##	thumbnailButton.texture_normal = thumbnailImageTexture
#	emit_signal("taken_snapshot", get_texture())
##	Remove trash.
#	queue_free()
#	filterPose = {}
##	pose = {}
#	used_points.resize(0)

func _generate_preview_scene(parent: Node = null, previewParent: Node = null, has_filtered: bool = false, iter: int = 0):
	# Loops through all of a Node's children in a maximum of %iter iterations.
	for ch in parent.get_children():
		var _np_ch: String = poseSceneRoot.get_path_to(ch)
		var _ch: Node
		if !has_filtered:
			if filterPose.has(_np_ch):
				has_filtered = true
#				continue
		
		if has_filtered:
			_ch = _generate_previewNode(ch)
		else:
			_ch = Node2D.new()
		previewParent.add_child(_ch)
		_generate_preview_scene(ch, _ch, has_filtered, iter-1)
#	print(previewParent.get_children()[0],' globaltrans =',previewParent.get_children()[0].global_transform)

func _generate_previewNode(ch :Node, is_poseroot: bool = false) -> Node:
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
		return _ch
	elif ch is CanvasItem:
		match ch.get_class():
			'Sprite':
				_ch = Sprite.new()
				if is_instance_valid(ch.texture):
					if ch.visible:
						_ch.texture = ch.texture
						_ch.offset = ch.offset
				else:
					_ch.texture = load("res://addons/posepal/assets/icons/icon_not.png")
					
				_ch.offset = ch.offset
				_ch.flip_h = ch.flip_h
				_ch.flip_v = ch.flip_v
				_ch.z_index = ch.z_index
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
	
	# Load default node transform
	if ch is Node2D:
		_ch.transform = ch.transform
	
	if my_nodepath in filterPose:
		for property in filterPose[my_nodepath]:
			var _copy_from_filter: bool = true
			if pose.has(my_nodepath):
				if pose[my_nodepath].has(property):
					_copy_from_filter = false
			if property in _ch && _copy_from_filter:
				_ch.set(property, filterPose[my_nodepath][property]['val'])
	
	if my_nodepath in pose:
		for property in pose[my_nodepath]:
			
			if property in _ch:
				if property == 'texture':
					_ch.set('texture', pose[my_nodepath]['texture']['val'])
					#_ch.set('texture', load(pose[my_nodepath]['texture']['val']))
					
				else:
					_ch.set(property, pose[my_nodepath][property]['val'])
					
#							_ch.scale = thumbnailButton.rect_size / _ch.texture.get_size()
#				print(my_nodepath,':',property,'=',_ch.get(property))
	if _ch is Sprite:
		var s:Sprite=_ch
		# Fallback to group's default properties.
#		if (!pose.has(my_nodepath)
#		&& !filterPose.has(my_nodepath)):
#			pass
		
		var can_calculate_full_rect: bool = false
		if can_calculate_full_rect:
			var _tr: Transform2D = get_node_global_transform(s)#s.get_transform()#.affine_inverse()
#			print(s,' lpos: ',s.position,' gpos:',get_node_global_pos(s))
#			print('origin, gpos, lpos: ',_tr.origin,', ',get_node_global_pos(s),', ',s.position)
#			var _tr :Transform2D= s.get_transform().affine_inverse()
			var rect: Rect2 = s.get_rect()
#			print('sprite rect ',rect)
#			if is_instance_valid(s.texture):
			used_points.append_array(PoolVector2Array([
				_tr.xform(rect.position), # TL
				_tr.xform(Vector2(rect.position.x, rect.end.y)), # BL
				_tr.xform(rect.end), # BR
				_tr.xform(Vector2(rect.end.x, rect.position.y)), # TL
			]))
			

	
	return _ch

func calculate_children_used_points(node: Node2D, iter: int):
	
#	print("name in node ", 'name' in node)
#	print("node has met ",node.has_method('get_child'))
#	print("name in node ", get_rect in node)
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

