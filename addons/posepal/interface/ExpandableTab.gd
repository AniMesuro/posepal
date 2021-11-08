tool
extends PanelContainer

export var path_to_expandableControl :NodePath= NodePath('.')
var expandableControl :Control

export var text :String setget _set_tab_text
export var icon :StreamTexture= load('res://icon.png') setget _set_tab_icon

export var expand :bool= true setget _set_expand

func _set_tab_text(new_text :String):
#	if !is_inside_tree():
#		print('outtree ',new_text)
#		return
#	if text == new_text:
#		print('text=newtext')
#		return
	text = new_text
	var label :Label= get_node_or_null("TabHBox/Label")
	if !is_instance_valid(label):
#		print('label not valid')
		return
	label.text = new_text

func _set_tab_icon(new_icon :StreamTexture):
#	if !is_inside_tree():
#		return
#	if icon == new_icon:
#		return
	icon = new_icon
	if !is_inside_tree():
#		print('outside tree')
		yield(self, "tree_entered")
#	yield(get_tree(), "idle_frame")
	var iconRect :TextureRect= get_node_or_null("TabHBox/Icon")
	if !is_instance_valid(iconRect):
#		pass
		print('iconRect invalid')
		return
	iconRect.texture = new_icon
#	print('iconrect ',iconRect.texture)

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
	
#	var is_inside_tab :bool= false
#	# Mouse is inside Tab
#	if (mouseInput.global_position > rect_global_position
#	&&	mouseInput.global_position < rect_global_position + rect_size):
#		print('mouse ',mouseInput.global_position,' tab ',rect_global_position,'/',rect_size)
#		is_inside_tab = true
	
	if mouseInput.button_index == BUTTON_LEFT:
		if mouseInput.pressed && !just_pressed:# && is_inside_tab:
			self.expand = !self.expand
			just_pressed = true
		elif !mouseInput.pressed && just_pressed:
			just_pressed = false

func _set_expand(new_expand :bool):
	expand = new_expand
#	if get_tree().edited_scene_root
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
			
			# debug svae button
			if new_expand:
				owner.save_poseData()
