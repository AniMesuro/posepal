tool
extends GridContainer

const SCN_AskNamePopup: PackedScene = preload("res://addons/posepal/interface/AskNamePopup.tscn")
const SCN_AskIDPopup: PackedScene = preload("res://addons/posepal/interface/AskIDPopup.tscn")
const SCN_PosePreview: PackedScene= preload("res://addons/posepal/interface/PosePreview.tscn")
const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var pageHBox: HBoxContainer

func _ready() -> void:
	_fix_PoseCreationHBox_ref()

var poseCreationHBox: HBoxContainer
func _fix_PoseCreationHBox_ref() -> void:
	poseCreationHBox = owner.get_node("VSplit/ExtraHBox/PoseCreationHBox")
	
func fill_previews(limit_by_page: bool = true):#true):
	# Bad practice - Prefer to reuse existing previews
	# and updating the new/old ones.
	_clear_previews()
	var poselib: RES_PoseLibrary = owner.currentPoselib
	if !is_instance_valid(poselib):
		return
	if !poselib.is_references_valid:
		return
	if !poselib.filterData.has(owner.poselib_filter):
		return
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return
	var editedSceneRoot: Node = get_tree().edited_scene_root
	if !is_instance_valid(editedSceneRoot.get_node(owner.poselib_scene)):
		return
	
	var collection: Array = poselib.poseData[owner.poselib_template][owner.poselib_collection]
	var pose_count: int = collection.size()
	if pose_count == 0:
		return
	
#	poselib.nodepathReferences
	var err_nodepath: int = poselib.validate_nodepaths(editedSceneRoot.get_node(owner.poselib_scene))
	if err_nodepath != OK:
		owner.issue_warning("broken_nodepaths")
		print("[posepal] Couldn't complete filling palette because broken nodepaths were found.")
	return
	
	pageHBox = $"../../HBox/PageHBox"
	pageHBox.update_pages()
	if pageHBox.current_page < 0:
		pageHBox.set('current_page', 0)
		return
		
	var pose_range: Array = []
	if !limit_by_page:
		pose_range = range(collection.size())
	else:
		pose_range = range(
			pageHBox.current_page * pageHBox.page_size,
			min(pageHBox.current_page * pageHBox.page_size + pageHBox.page_size, pose_count))
	for pose_id in pose_range:
		var pose: Dictionary = collection[pose_id]
		# Ignore if pose doesn't have all nodes from Filter pose.
		if owner.poselib_filter != 'none':
			var inside_filter: bool = _filter_previews(pose, poselib)
			if !inside_filter:
				continue
		
		var posePreview: VBoxContainer = SCN_PosePreview.instance()
		add_child(posePreview)
		var pose_name: String = ""
		if pose.has('_name'):
			pose_name = pose['_name']
			posePreview.label.text = str(pose_id) + ":" + pose_name
			posePreview.hint_tooltip = posePreview.label.text
		else:
			posePreview.label.text = str(pose_id)
		
		
		posePreview.pose_id = pose_id
		posePreview.pose_name = pose_name
		posePreview.pose = pose#collection[pose_id]
		posePreview.poseSceneRoot = editedSceneRoot.get_node(owner.poselib_scene)
		posePreview.generate_thumbnail()
	var zoomSlider: HSlider = $"../../HBox/ZoomHBox/ZoomSlider"
	
	zoomSlider._update_frame_sizes()
	yield(get_tree(), "idle_frame")
	zoomSlider._fix_columns()
	
func _clear_previews():
	for posePreview in get_children():
		posePreview.queue_free()

func _filter_previews(pose: Dictionary, poselib: RES_PoseLibrary) -> bool:
	var first = true
	var inside_filter: bool = false
	
	var highest_filtered_parents_path: PoolStringArray = []
	var highest_filtered_parents_level: PoolIntArray= []
	var pose_raw: Dictionary = pose
	
	pose_raw.erase('_name')
	for node_path in pose:
		if node_path == '_name':
			continue
		
		# Loop through all parents to see if any of them is filtered
		# Find highest filtered level parent.
		var nodepath_array: PoolStringArray = node_path.split('/', false, 15)
		var current_path: String = nodepath_array[0]
		for i in nodepath_array.size():
			if i > 0:
				current_path = current_path +'/'+ nodepath_array[i]
			if current_path in highest_filtered_parents_path:
				break
			if poselib.filterData[owner.poselib_filter].has(current_path):
				highest_filtered_parents_path.append(current_path)
				highest_filtered_parents_level.append(i)
				break
			
			if i in highest_filtered_parents_level && (i > 0):
				var parent_path: String = current_path.trim_suffix("/"+ nodepath_array[i])
				for path in highest_filtered_parents_path:
					var high_path: String = path
					var high_path_parent: String = high_path.rsplit('/', false, 1)[0]
					if high_path_parent == parent_path:
						return false
	return true
