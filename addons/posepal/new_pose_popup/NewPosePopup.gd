#tool
extends Popup

signal pose_created (pose, pose_key)

var handlerTop :ReferenceRect
var handlerBottom :ReferenceRect
var handlerLeft :ReferenceRect
var handlerRight :ReferenceRect

#var pose :Dictionary # A pose is a Dictionary that holds node keys and property child keys.
var poseData :Dictionary
var poselib_template :String
var poselib_face :String
var poselib_scene :NodePath
var pose_id :int

var pluginInstance :EditorPlugin
var poseLibraryDock :Control
var treeDisplay :VBoxContainer
var doneButton :Button

func _enter_tree() -> void:
	if get_tree().edited_scene_root == self:
		visible = true
		
		
func _ready() -> void:
#	if get_tree().edited_scene_root == self:
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
#	pluginInstance.connect("scene_changed", self, "_on_scene_changed")
	print('plugininstance ',pluginInstance)
#		$"Panel/VBox/TabContainer/Properties/PropertyDisplay".pluginInstance = pluginInstance
#		$"Panel/VBox/TabContainer/Nodes/TreeDisplay".pluginInstance = pluginInstance
	
	treeDisplay = $"Panel/VBox/TabContainer/Nodes/TreeDisplay"
	doneButton = $"Panel/VBox/ButtonHBox/DoneButton"
	doneButton.connect("pressed", self, "_on_DoneButton_pressed")
	connect("hide", self, "_on_hide")
	
	rect_min_size = $Panel.rect_min_size + Vector2(2,2)
#	rect_size = rect_size + Vector2(2,2)

func setup(_poseLibraryDock :Control, available_id :int) -> void:
	if !is_instance_valid(_poseLibraryDock):
		print('poselibdock not valid')
		return
	poseLibraryDock = _poseLibraryDock
	poseLibraryDock.load_poseData()
	
	poselib_template = poseLibraryDock.poselib_template
	poselib_face = poseLibraryDock.poselib_face
	poseData = poseLibraryDock.poseData
	poselib_scene = poseLibraryDock.poselib_scene
	pose_id = available_id
	
#	pluginInstance = poseLibraryDock.pluginInstance
#	pluginInstance.connect("scene_changed", self, "_on_scene_changed")
#	$"Panel/VBox/TabContainer/Properties/PropertyDisplay".pluginInstance = pluginInstance
#	$"Panel/VBox/TabContainer/Nodes/TreeDisplay".pluginInstance = pluginInstance
	
	treeDisplay.fill_nodes()
	
#func _on_scene_changed(sceneRoot :Node):
#	 If being edited.
#	if sceneRoot or get_tree().edited_scene_root == self:
#		return
#
#	queue_free()

func _on_DoneButton_pressed():
	# Save pose to PoseData
	var pose :Dictionary= $"Panel/VBox/TabContainer/Properties/PropertyDisplay".pose
#	var editedSceneRoot :Node= get_tree().edited_scene_root
#	var poseSceneRoot :Node= editedSceneRoot.get_node(poselib_scene)
	
	if !poselib_template in poseLibraryDock.poseData:
		poseLibraryDock.poseData[poselib_template] = {}
	if !poselib_face in poseLibraryDock.poseData[poselib_template]:
		poseLibraryDock.poseData[poselib_template][poselib_face] = {}
	if !str(pose_id) in poseLibraryDock.poseData[poselib_template][poselib_face]:
		poseLibraryDock.poseData[poselib_template][poselib_face][str(pose_id)] = pose
	
	# Save pose to PoseLib file
	
	emit_signal("pose_created", pose, str(pose_id))
	queue_free()

func _on_hide():
	# If being edited.
	if get_tree().edited_scene_root == self:
		return

	queue_free()

