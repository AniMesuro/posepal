tool
extends Control

export var path_to_expandableControl: NodePath = NodePath('.')
var expandableControl: Control

export var text: String setget _set_tab_text
export var icon: StreamTexture = load('res://icon.png') setget _set_tab_icon
export var expand: bool = true setget _set_expand

func _set_tab_text(new_text :String):
	text = new_text
	var label: Label = get_node_or_null("TabHBox/Label")
	if !is_instance_valid(label):
		return
	label.text = new_text

func _set_tab_icon(new_icon :StreamTexture):
	icon = new_icon
	if !is_inside_tree():
		yield(self, "tree_entered")
	var iconRect :TextureRect= get_node_or_null("TabHBox/Icon")
	if !is_instance_valid(iconRect):
		return
	iconRect.texture = new_icon

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
		if mouseInput.pressed && !just_pressed:# && is_inside_tab:
			self.expand = !self.expand
			just_pressed = true
		elif !mouseInput.pressed && just_pressed:
			just_pressed = false

func _set_expand(new_expand :bool):
	expand = new_expand
	if !is_inside_tree():
		return
	
	expandableControl = get_node(path_to_expandableControl)
	if is_instance_valid(expandableControl):
		if expandableControl == self:
			return
		if "visible" in expandableControl:
			expandableControl.visible = new_expand
			var expandIcon :TextureRect= $TabHBox/ExpandIcon
			expandIcon.flip_v = new_expand
			
