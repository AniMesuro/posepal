tool
extends PanelContainer

export var path_to_expandableControl: NodePath = NodePath('.')
export var text: String setget _set_tab_text
export var is_locked: bool = true setget _set_is_locked
export var expand: bool = true setget _set_expand

var expandableControl: Control
func _set_tab_text(new_text :String):
	if new_text == '':
		return
	if !is_inside_tree():
		if is_instance_valid(self):
			yield(self, "tree_entered")
	var label: Label = $"HBox/Label"
	
	text = new_text
	label.text = new_text

func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	if get_tree().edited_scene_root == get_parent().owner:
		return
	
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	set_process_input(false)
	
func _on_mouse_entered():
	set_process_input(true)
	
func _on_mouse_exited():
	set_process_input(false)
	just_pressed = false

var just_pressed = false
func _input(event: InputEvent) -> void:
	if !event is InputEventMouseButton:
		return
	var mouseInput :InputEventMouseButton= event
	
	if mouseInput.button_index == BUTTON_LEFT:
		if is_locked:
			return
		if mouseInput.pressed && !just_pressed:
			self.expand = !self.expand
			just_pressed = true
		elif !mouseInput.pressed && just_pressed:
			just_pressed = false

func _set_expand(new_expand :bool):
	expand = new_expand
	if !is_inside_tree():
		return
	if is_locked:
		expand = false
	
	expandableControl = get_node(path_to_expandableControl)
	if is_instance_valid(expandableControl):
		if expandableControl == self:
			return
		if "visible" in expandableControl:
			expandableControl.visible = expand
			var expandIcon :TextureRect= $HBox/ExpandIcon
			expandIcon.flip_v = expand

func _set_is_locked(new_is_locked: bool):
	if is_locked == new_is_locked:
		return
	
	is_locked = new_is_locked
	if is_locked:
		self.expand = false
		visible = false
	else:
		self.expand = expand
		visible = true
