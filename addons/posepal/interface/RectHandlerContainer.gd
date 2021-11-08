tool
extends Control

export var handler_size :int setget set_handler_size
export var _windowRect :NodePath setget _set_windowRect

var _visible :bool= false setget set_pseudovisible

export var debug_mode :bool= false setget _set_debug_mode

var handlerTop :ReferenceRect
var handlerBottom :ReferenceRect
var handlerLeft :ReferenceRect
var handlerRight :ReferenceRect


func _ready() -> void:
	connect("visibility_changed", self, "_on_visibility_changed")

func _enter_tree() -> void:
	if !is_instance_valid(self):
		yield(get_tree(), "idle_frame")
	handlerTop = $HandlerTop
	handlerBottom = $HandlerBottom
	handlerLeft = $HandlerLeft
	handlerRight = $HandlerRight
	
#	self._set_windowRect = self._set_windowRect



func _set_windowRect(value :NodePath):
	if !is_inside_tree():
		yield(self, "tree_entered")
	if !is_instance_valid(self):
		return
	var _window = get_node(value)
	if !is_instance_valid(_window):
		return
	
	_windowRect = value
	for child in get_children():
		if !child is ReferenceRect:
			continue
		child._windowRect = child.get_path_to(_window)
	

func set_handler_size(value :int):
	handler_size = value
	for child in get_children():
		if !child is ReferenceRect:
			continue
		child.handler_size = value
		child._fix_handler_rect(child.handler_direction)

#Istead of making the handlers visible/invisible, it will make the modulate alpha 0
#ReferenceRect doesn't appear to execute when invisible.
func set_pseudovisible(value :bool):
	var windowRect = get_node(_windowRect)
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
		#If window is being edited, toggle _visible, this node should not be visible from being instanced
		if get_tree().edited_scene_root == windowRect.owner:
			modulate = Color.white
		else:
			modulate = Color.transparent
	else:
		modulate = Color.transparent

func _on_visibility_changed():
	if !is_instance_valid(self):
		return
	if !is_inside_tree():
		return
	if is_connected( "visibility_changed", self, "_on_visibility_changed"):
		disconnect( "visibility_changed", self, "_on_visibility_changed")
#	print('visible ',visible)
	self._visible = !_visible
	if !visible: visible = true
	connect( "visibility_changed", self, "_on_visibility_changed")

func _set_debug_mode(value :bool):
	debug_mode = value
	
	for child in get_children():
		if child.debug_mode != debug_mode:
			child.debug_mode = debug_mode
