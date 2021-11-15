#tool
extends VBoxContainer

const SCN_PropertyTab :PackedScene= preload("res://addons/posepal/new_pose_popup/property_display/PropertyTab.tscn")

var pose :Dictionary= {} # Remote with all PropertyTabs
#var jsonPose :Dictionary= {} # Stores only values incompatible with JSON. ex: Resources
var last_selected_nodepaths :PoolStringArray= PoolStringArray([])

var pluginInstance :EditorPlugin
var poseSceneRoot :Node

func _ready() -> void:
	pluginInstance = get_tree().get_nodes_in_group("plugin pose_library")[0]

func fill_tabs():
	clear_tabs()
	
	var editedSceneRoot :Node= get_tree().edited_scene_root
	poseSceneRoot = editedSceneRoot.get_node_or_null(owner.poselib_scene)
	if !is_instance_valid(poseSceneRoot):
		return
	
	for i in last_selected_nodepaths.size():
		var nodepath :String= last_selected_nodepaths[i]
		var propertyTab :VBoxContainer= SCN_PropertyTab.instance()
		add_child(propertyTab)
		if !pose.has(nodepath):
			pose[nodepath] = {}
		
		var node :Node= poseSceneRoot.get_node(nodepath)
		propertyTab.node_nodepath = nodepath
		propertyTab.node_type = node.get_class()
	print('pose = ',pose)

func clear_tabs():
	for tab in get_children():
		tab.queue_free()
