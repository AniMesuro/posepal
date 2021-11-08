tool
extends GridContainer

var pageHBox: HBoxContainer

const SCN_AskNamePopup: PackedScene = preload("res://addons/posepal/interface/AskNamePopup.tscn")
const SCN_AskIDPopup: PackedScene = preload("res://addons/posepal/interface/AskIDPopup.tscn")
const SCN_PosePreview: PackedScene= preload("res://addons/posepal/interface/PosePreview.tscn")
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

# Updates PosePallette display to show each PosePreview
func update_display():
	pass

func _ready() -> void:
	_fix_PoseCreationVBox_ref()
	pageHBox = owner.get_node("VSplit/ExtraHBox/VBox/PageHBox")

var poseCreationVBox: VBoxContainer
func _fix_PoseCreationVBox_ref() -> void:
	poseCreationVBox = owner.get_node("VSplit/ExtraHBox/PoseCreationVBox")
	

# [] Todo generate 1 dummy scene then just pose and print 9 times.
func fill_previews():
	# Bad practice - Prefer to reuse existing previews
	# and updating the new/old ones.
	_clear_previews()
	print('starting to fill')
	# <TODO> Limit preview maximum by 9 for each page. 
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		print('poselib resource not valid')
#	if owner.poseData == {}:
		return
#	if !owner.poseData.has('collections'):
#		return
	if !poselib.filterData.has(owner.poselib_filter):
		print('')
		return
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return
	var editedSceneRoot: Node = get_tree().edited_scene_root
	if !is_instance_valid(editedSceneRoot.get_node(owner.poselib_scene)):
		return
	
	var subcol: Array = poselib.poseData[owner.poselib_template][owner.poselib_collection]
	for pose_id in subcol.size():
		var pose: Dictionary = subcol[pose_id]
		# Ignore if pose doesn't have all nodes from Filter pose.
		if owner.poselib_filter != 'none':
			var inside_group: bool = true
			for node_path in pose:
				# This approach ignores filtered children.
				if node_path == '_name':
					continue
				if !poselib.filterData[owner.poselib_filter].has(node_path):
				# Might be expensive, but filtered children are noted.
#				if poselib.filterData[owner.poselib_filter].has(node_path):
					inside_group = false
					break
				
				
			if !inside_group:
				continue
		
		var posePreview: VBoxContainer = SCN_PosePreview.instance()
		add_child(posePreview)
#		print('pose '+pose)
		var pose_name: String = ""
		if pose.has('_name'):
			pose_name = pose['_name']
			posePreview.label.text = str(pose_id) + ":" + pose_name
			posePreview.hint_tooltip = posePreview.label.text
		else:
			posePreview.label.text = str(pose_id)
			
		posePreview.pose_id = pose_id
		posePreview.pose_name = pose_name
		
		
		
		posePreview.pose = subcol[pose_id]
		posePreview.poseSceneRoot = editedSceneRoot.get_node(owner.poselib_scene)
		posePreview._generate_thumbnail()
			
#		print('posekey =',posePreview.pose_key)
	var zoomSlider :HSlider= owner.get_node('VSplit/ExtraHBox/VBox/ZoomHBox/ZoomSlider')
	
	zoomSlider._update_frame_sizes()
	yield(get_tree(), "idle_frame")
	zoomSlider._fix_columns()
#	zoomSlider._update_frame_sizes()

func _clear_previews():
	for posePreview in get_children():
		posePreview.queue_free()
