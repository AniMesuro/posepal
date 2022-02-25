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
#	pageHBox = 

var poseCreationVBox: VBoxContainer
func _fix_PoseCreationVBox_ref() -> void:
	poseCreationVBox = owner.get_node("VSplit/ExtraHBox/PoseCreationVBox")
	

# [] Todo generate 1 dummy scene then just pose and print 9 times.
func fill_previews(limit_by_page: bool = true):#true):
	# Bad practice - Prefer to reuse existing previews
	# and updating the new/old ones.
	_clear_previews()
#	print('starting to fill')
	# <TODO> Limit preview maximum by 9 or 10 for each page. 
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
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
	
	var collection: Array = poselib.poseData[owner.poselib_template][owner.poselib_collection]
	var pose_count: int = collection.size()
	if pose_count == 0:
		return
	var pageHBox: HBoxContainer = $"../../PageHBox"
	
	pageHBox.update_pages()#update_NumButton_item_list()
	if pageHBox.current_page == -1:
		pageHBox.current_page = 0
		
	var pose_range: Array = []
	if !limit_by_page:
		pose_range = range(collection.size())
	else:
#		pageHBox.current_page
#		pose_range = range(1, 1+9)
		pose_range = range(
			pageHBox.current_page * pageHBox.page_size,
			min(pageHBox.current_page* pageHBox.page_size + pageHBox.page_size, pose_count))
		
#		pose_range = range(pose_count* .1, pose_count * .1+9)
#	var pose_range = range(first_pose_id, last_pose_id)
	for pose_id in pose_range:#collection.size():
		var pose: Dictionary = collection[pose_id]
		# Ignore if pose doesn't have all nodes from Filter pose.
		if owner.poselib_filter != 'none':
			var inside_filter: bool = _filter_previews(pose, poselib)
				
				
			if !inside_filter:
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
		
		
		
		posePreview.pose = collection[pose_id]
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

func _filter_previews(pose: Dictionary, poselib: RES_PoseLibrary) -> bool:
	var first = true
	var inside_filter: bool = false
#	var highest_filtered_parent_path: String = ""
#	var highest_filtered_parent_level: int = -1
#	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.poselib_scene)
	
	var highest_filtered_parents_path: PoolStringArray = []
	var highest_filtered_parents_level: PoolIntArray= []
	
	var pose_raw: Dictionary = pose
	pose_raw.erase('_name')
	
	for node_path in pose:
		# This approach ignores filtered children.
		if node_path == '_name':
			continue
		
		# Loop through all parents to see if any of them is filtered
		# Find highest filtered level parent.
		var nodepath_array: PoolStringArray = node_path.split('/', false, 15)
#		print('nodepath array ',nodepath_array)
		var current_path: String = nodepath_array[0]#node_path
		
		
#		while nodepath_array.size() > 0:
		for i in nodepath_array.size():
			if i>0:
				current_path = current_path +'/'+ nodepath_array[i]
			
			if current_path in highest_filtered_parents_path:
				break
			if poselib.filterData[owner.poselib_filter].has(current_path):
				highest_filtered_parents_path.append(current_path)
				highest_filtered_parents_level.append(i)
#				highest_filtered_parent_path = current_path
#					inside_filter = true
#					Maybe doesn't need break because a filter can have multiple parents
				break
			
			# Parents seems to be ignored already.
			
			# If siblings
			if i in highest_filtered_parents_level && (i > 0):
				var parent_path: String = current_path.trim_suffix("/"+ nodepath_array[i])
#				print('parent_path ',parent_path)
				for path in highest_filtered_parents_path:
					var high_path: String = path
#					print('high path ',high_path)
					
					var high_path_parent: String = high_path.rsplit('/', false, 1)[0]
#					print('high path -- ',high_path_last_node)
					if high_path_parent == parent_path:
#						print('nodepath slice ',i,' sibling with highest')
						
						return false
			
#			if nodepath_array.size() > 1:
#				current_path = current_path.trim_suffix('/'+nodepath_array[nodepath_array.size()-1])
#			else:
#				print('--  last one', nodepath_array)
#
#				current_path = current_path.trim_suffix(nodepath_array[nodepath_array.size()-1])
			
#			if first: print('current_path ', current_path,' | ', nodepath_array)
#			nodepath_array.remove(nodepath_array.size()-1)
#					if pose_id == 0: print("current path =", current_path)
#					return
#		first = false
		# At least one node in filter
#				if !poselib.filterData[owner.poselib_filter].has(node_path):
#					inside_filter = false
#					break
	return true
