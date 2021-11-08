tool
extends ReferenceRect

export var handler_size :int
enum DIRECTION {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT
}
export (DIRECTION) var handler_direction  = DIRECTION.TOP setget _set_handler_direction

export var debug_mode :bool= false # Will make recthandler always visible

var following :bool= false
var mouse_offset :Vector2
var window_position :Vector2
var window_size :Vector2
var distance_to_edge :Vector2
var window_distance :Vector2

var last_mouse_position :Vector2
var last_size :Vector2

var _visible :bool= false setget set_pseudovisible
#var window_distance_tl :Vector2 #topleft
#var window_distance_br :Vector2 #bottomright

var handlerContainer :Control
export var _windowRect :NodePath setget _set_windowRect
var windowRect :Control 

func _ready() -> void:
	connect( "gui_input", self, "_on_RectHandler_gui_input")
	connect( "visibility_changed", self, "_on_visibility_changed")

func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		self._visible = true
		return
		
	if is_instance_valid(windowRect):
		if handler_size == 0: handler_size = 10
		_fix_handler_rect(handler_direction)
		if get_tree().edited_scene_root == windowRect.owner:
			set_process(false)
			return

func _set_handler_direction(value :int):
	handler_direction = value
	if _windowRect == null:
		print(name,' path to window node is null')
		return
	
	if !is_instance_valid(self):
		return
	if !is_inside_tree():
		yield(self, "tree_entered")
	_fix_handler_rect(value)

func _fix_handler_rect(direction :int):
	if !is_instance_valid(self):
		return
	if !is_inside_tree():
		yield(self, "tree_entered")
	if !is_instance_valid(windowRect):
		return
	
	
	match direction:
		DIRECTION.BOTTOM:
			rect_position.x = 0
			rect_global_position.y = windowRect.rect_global_position.y + windowRect.rect_size.y - handler_size
			rect_size = Vector2(windowRect.rect_size.x, handler_size)
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
			
			distance_to_edge.y = windowRect.rect_size.y - rect_global_position.y # position from windowrect title to OS titlebar?
		
		DIRECTION.TOP:
			rect_position = Vector2(0,0)
			rect_global_position = windowRect.rect_global_position
			rect_size = Vector2(windowRect.rect_size.x, handler_size)
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
			
			distance_to_edge = windowRect.rect_size - rect_global_position
		DIRECTION.RIGHT:
			rect_position.y = 0
			rect_global_position.x = windowRect.rect_global_position.x + windowRect.rect_size.x - handler_size
			rect_size = Vector2(handler_size, windowRect.rect_size.y)
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
			
			distance_to_edge = windowRect.rect_size - rect_global_position
		DIRECTION.LEFT:
			rect_position = Vector2(0,0)
			rect_global_position = windowRect.rect_global_position
			rect_size = Vector2(handler_size, windowRect.rect_size.y)
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
			
			distance_to_edge = windowRect.rect_size - rect_global_position
			
	window_distance = Vector2(
		windowRect.rect_size.x - rect_global_position.x,
		windowRect.rect_size.y - rect_global_position.y
	)
	

func _set_windowRect(value :NodePath= _windowRect):
	#if is running on editor.
	if !is_instance_valid(self):
		return
	if !is_inside_tree():
		yield(self, "tree_entered")
	if get_tree().edited_scene_root == self:
		return
	
	var _window = get_node_or_null(value)
	
	if !is_instance_valid(_window):
		return
	if !_window is Control:
		return
	if _window == self:
		return
	
	_windowRect = value
	windowRect = get_node(get_path_to(_window))
	if _is_in_RectContainer():
		handlerContainer = get_parent()
	else:
		handlerContainer = windowRect
	
	match handler_direction:
		DIRECTION.TOP:
			if _is_in_RectContainer():
				handlerContainer.handlerTop = self
			elif "handlerTop" in windowRect:
				handlerContainer.handlerTop = self
			else:
				return
		DIRECTION.BOTTOM:
			if _is_in_RectContainer():
				handlerContainer.handlerBottom = self
			elif "handlerBottom" in windowRect:
				handlerContainer.handlerBottom = self
			else:
				return
		DIRECTION.LEFT:
			if _is_in_RectContainer():
				handlerContainer.handlerLeft= self
#				return
			elif "handlerLeft" in windowRect:
				handlerContainer.handlerLeft= self
			else:
				return
		DIRECTION.RIGHT:
			if _is_in_RectContainer():
				handlerContainer.handlerRight = self
#				return
			elif "handlerRight" in windowRect:
				handlerContainer.handlerRight = self
			else:
				return
	_fix_handler_rect(handler_direction)
	if get_tree().edited_scene_root == windowRect.owner:
		if modulate == Color.transparent:
			modulate = Color.white
#	print("windowRect doesn't have handler reference variables. Please define references on ",windowRect.name," or use another Control node")

func _on_RectHandler_gui_input(event :InputEvent):
	if event is InputEventMouseButton:
		if event.get_button_index() == BUTTON_LEFT:
			mouse_offset = get_local_mouse_position()
			#assumes Scene owner is a window.
			
			window_position  = windowRect.rect_global_position
			window_size = windowRect.rect_size
			
			last_mouse_position = get_global_mouse_position() 
			last_size = windowRect.rect_size #+ mouse_offset
			following = !following

func _is_in_RectContainer() -> bool:
	if get_tree().edited_scene_root == self:
		return false
	if get_parent().get_script() == null:
		return false
	
	if get_parent().get_script().resource_path == "res://addons/rhubarb_lipsync_integration/interface/RectHandlerContainer.gd":
		return true
	return false

func _process(delta: float) -> void:
	if following:
		match handler_direction:
			DIRECTION.BOTTOM:
				windowRect.rect_size.y = last_size.y - (last_mouse_position.y-get_global_mouse_position().y)
				rect_global_position.y = window_position.y + windowRect.rect_size.y - handler_size
				
				handlerContainer.handlerLeft.rect_size.y = windowRect.rect_size.y
				handlerContainer.handlerRight.rect_size.y = windowRect.rect_size.y
			DIRECTION.TOP:
				windowRect.rect_global_position.y = get_global_mouse_position().y - mouse_offset.y
				windowRect.rect_size.y = last_size.y + last_mouse_position.y - get_global_mouse_position().y  
				
				handlerContainer.handlerBottom.rect_global_position.y = windowRect.rect_global_position.y + windowRect.rect_size.y - handler_size
				handlerContainer.handlerLeft.rect_size.y = windowRect.rect_size.y
				handlerContainer.handlerRight.rect_size.y = windowRect.rect_size.y
			DIRECTION.RIGHT:
				windowRect.rect_size.x = last_size.x - (last_mouse_position.x - get_global_mouse_position().x)
				rect_global_position.x = window_position.x + windowRect.rect_size.x - handler_size
#				windowRect.rect_size.x = get_global_mouse_position().x - mouse_offset.x + window_distance.x
#				rect_global_position.x = windowRect.rect_size.x - window_distance.x
				
				handlerContainer.handlerTop.rect_size.x = windowRect.rect_size.x
				handlerContainer.handlerBottom.rect_size.x = windowRect.rect_size.x
			DIRECTION.LEFT:
				windowRect.rect_global_position.x = get_global_mouse_position().x - mouse_offset.x
				windowRect.rect_size.x = last_size.x + last_mouse_position.x - get_global_mouse_position().x#- mouse_offset.x

				handlerContainer.handlerRight.rect_global_position.x = windowRect.rect_global_position.x + windowRect.rect_size.x - handler_size
				handlerContainer.handlerTop.rect_size.x = windowRect.rect_size.x
				handlerContainer.handlerBottom.rect_size.x= windowRect.rect_size.x

# This is stupidly overcomplicated, but it works for now.

func set_pseudovisible(value :bool):
	if !is_inside_tree():
		yield(self, "tree_entered")
	if !is_instance_valid(windowRect):
		return
		
	if debug_mode:
		modulate = Color.white 
		_visible = true
		return
	
	_visible = value
	if value:
		if get_tree().edited_scene_root == windowRect.owner:
#			if modulate == Color.transparent:
			modulate = Color.white
		else:
			modulate = Color.transparent
	else:
	#	if get_tree().edited_scene_root == windowRect.owner:
		modulate = Color.transparent

func _on_visibility_changed():
	if !is_instance_valid(self):
		return
	if is_connected( "visibility_changed", self, "_on_visibility_changed"):
		disconnect( "visibility_changed", self, "_on_visibility_changed")
	self._visible = !_visible
	if !visible: visible = true
	connect( "visibility_changed", self, "_on_visibility_changed")
