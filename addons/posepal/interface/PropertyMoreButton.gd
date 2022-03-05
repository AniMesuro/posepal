tool
extends MenuButton

const SCN_AskNamePopup: PackedScene = preload("res://addons/posepal/interface/AskNamePopup.tscn")

enum Items {
	EDIT,
	CREATE,
	RENAME,
	ERASE,
	APPLY,
	KEY
}

var popupMenu :PopupMenu
var askNamePopup: Popup 
func _ready() -> void:
	if get_tree().edited_scene_root == get_parent().owner:
		return
	popupMenu = get_popup()
	popupMenu.clear()
	
	popupMenu.connect("id_pressed", self, "_on_id_pressed")
	connect("pressed", self, "_on_pressed")

func _is_selected_scene_valid() -> bool:
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node_or_null(owner.poselib_scene)
	
	if !is_instance_valid(poseSceneRoot):
		popupMenu.hide()
		owner.issue_warning('scene_not_selected')
		return false
	return true

func ask_for_name(title_name: String):
	if is_instance_valid(askNamePopup):
		askNamePopup.queue_free()
	askNamePopup = SCN_AskNamePopup.instance()
	
	add_child(askNamePopup)
	askNamePopup.titlebar.title_name = title_name
	askNamePopup.label.text = "Please avoid special characters (e.g. !@*-=óü~/?;| etc.)"
	return askNamePopup
