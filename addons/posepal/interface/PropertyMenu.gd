tool
extends MenuButton

const TEX_ExpandIcon: StreamTexture = preload("res://addons/posepal/assets/icons/icon_expand.png")

export var msg_no_selection: String = ""
export var owner_reference: String= 'poselib_'

var popup :PopupMenu
func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return
	
	popup = get_popup()
	connect("pressed", self, "_on_pressed")
	popup.connect("id_pressed", self, "_on_id_selected")
	owner.connect("updated_reference", self, "_on_PoseLibrary_updated_reference")
	owner.connect("issued_forced_selection", self, "_on_issued_forced_selection")
	text = msg_no_selection

func _reset_selection():
	text = msg_no_selection
	icon = TEX_ExpandIcon

#func _on_PoseLibrary_updated_reference(reference :String):
#	# Checks if own property is valid.
#	if owner.get(owner_reference)
