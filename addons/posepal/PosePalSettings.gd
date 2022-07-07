tool
extends Resource

enum PoselibExtensions {
	tres,
	res,
}
export (PoselibExtensions) var poselib_extension

enum BoolToggle {
	off,
	on,
}
export (BoolToggle) var debug_mode



export var enable_addons_integration: bool = true
export var integrations: Dictionary = {
	'animation_frame_picker': true
}

var pluginInstance: EditorPlugin 
func is_addon_active(addon_name: String):
	if (!enable_addons_integration or !integrations.get(addon_name, false)
	or  !is_instance_valid(pluginInstance)):
		return false
	if pluginInstance.get_tree().get_nodes_in_group("plugin "+addon_name).size()>0:
		return true

func get_plugin_instance_for(addon_name):
	if !enable_addons_integration or !integrations.get(addon_name, false):
		return null
	var _plugin_group: Array = pluginInstance.get_tree().get_nodes_in_group("plugin "+addon_name)
	for node in _plugin_group:
		if node is EditorPlugin:
			return node
	return null


