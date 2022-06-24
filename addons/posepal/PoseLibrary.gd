tool
extends Resource

# Please do not change poselib files manually (unless for debugging)
# Try to update it from the dock if possible.
# ------------

# Scene path
export var owner_filepath: String = "res://"
export var poselib_version: PoolIntArray = [0, 9, 0]

enum ReferenceType {
	PATH,
	RESOURCE
}
export var resourceReferences:  Dictionary = {} # Resource path ref ex. {0: "res://eyes.png"}
var resourceReferences_res: 	Dictionary = {} # Resource ref ex. {0: [StreamTexture:1234]}
export var available_res_id: int = 0
var is_references_valid: bool = true
export var nodepathReferences: Dictionary = {} # nodepath ref (from root) ex. {0: "Pelvis/Torso/LarmTop/LarmBottom/LHand"}
export var available_nodepath_id: int = 0
var is_nodepath_references_valid: bool = true

export var poseData: Dictionary = {"default": {"default": []}}
export var filterData: Dictionary = {"none": {}}
export var templateData: Dictionary = {"default": {}}

# Only used for scenes with skeleton2d
export (Dictionary) var boneRelationshipData = {}  # {'Sprite/Polygon2D': 'BSprite/BPolygon2D'}

var filtered_pose_ids: Array = [] # [0,3,6,12,13] shows the pose_ids visible within filters.

var pluginInstance: EditorPlugin
var posepalDock: Control
func setup(_pluginInstance: EditorPlugin, dock: Control):
	if !is_instance_valid(_pluginInstance):
		return
	pluginInstance = _pluginInstance
	posepalDock = dock
	update_poselib()
#	prepare_loading_resourceReferences()

# 0 OK 
# Resources don't track dependency, so it'll store only paths again.
func prepare_loading_resourceReferences() -> int:
	is_references_valid = true
	if resourceReferences.size() == 0:
		return FAILED
	if resourceReferences.values()[0] is Array:
		for k in resourceReferences.keys():
			resourceReferences[k] = resourceReferences[k][0]
		
	for k in resourceReferences.keys():
		var path: String = resourceReferences[k]
		if ResourceLoader.exists(path):
			resourceReferences_res[k] = ResourceLoader.load(path)
		else:
			is_references_valid = false
			return ERR_FILE_MISSING_DEPENDENCIES
	return OK

func validate_nodepaths():
	if !is_instance_valid(posepalDock):
		return
	var poseRoot: Node = posepalDock.get_tree().edited_scene_root.get_node_or_null(posepalDock.poselib_scene)
	
	for nodepath in nodepathReferences:
		print(nodepath)
	pass

func prepare_saving_resourceReferences():
	# Delete all actual resource references.
	# It's stored on an unxerported variable now so it's fine.
	pass

func clear():
	owner_filepath = "res://"
	poseData = {"default": {"default": []}}
	filterData = {"none": {}}
	templateData = {"default": {}}
	available_res_id = 0
	resourceReferences = {}
	poselib_version = [0,9,0] # latest version

#func get_nodepath_from_id(id: int):
#	if !nodepathReferences.has(id):
#		return ''
#	var nodepath: String
#	nod

func get_res_from_id(id: int):
	if !resourceReferences.has(id):
		return null
	var res: Resource
	if resourceReferences_res.has(id):#[id].size() != 1:
		res = resourceReferences_res[id]
	else:
		res = load(resourceReferences[id])
	return res

func get_id_from_path(path: String):
	for k in resourceReferences.keys():
		var res_path = resourceReferences[k]
		if res_path == path:
			return k

func get_id_from_res(res: Resource):
	for k in resourceReferences.keys():
		var res_path: String = resourceReferences[k]
		if res_path == res.resource_path:
			return k
			
	var id: int	
	var max_iter: int = 100
	var iter: int = 0
	
	while (resourceReferences.has(available_res_id + iter) && (iter < max_iter)):
		iter += 1
	id = available_res_id + iter
	available_res_id = id + 1
	resourceReferences[id] = res.resource_path#[res.resource_path, res]
	return id;
	
func get_res_paths() -> Array:
	return resourceReferences.values()

func get_id_from_nodepath(nodepath: String):
	for np_id in nodepathReferences.keys():
		var ref_np: String = nodepathReferences[np_id]
		if ref_np == nodepath:
			return np_id
			
	var id: int	
	var max_iter: int = 100
	var iter: int = 0
	while (resourceReferences.has(available_nodepath_id + iter) && (iter < max_iter)):
		iter += 1
	id = available_nodepath_id + iter
	available_nodepath_id = id + 1
	nodepathReferences[id] = nodepath
	return id

func get_nodepath_from_id(id: int):
	if !nodepathReferences.has(id):
		return ''
	return nodepathReferences[id]

# Attempts to update to latest version.
func update_poselib():
#	var current_version: PoolIntArray = poselib_version # current version
	var latest_version: PoolIntArray = pluginInstance.plugin_version # latest version
	
#	var ver1: PoolIntArray = [0,9,0]
#	var ver2: PoolIntArray = [0,9,1]
	
#	Updating is cumulative, only <0.8.9 is ignored.

#	if _version_is_older_than([0,8,9]):
#		print("[posepal] Poselib version too old, couldn't update file to latest version.")
#		return
	var has_updated: bool = false
	if _version_is_older_than([0,9,1]):
		print("[posepal] Poselib older than 0.9.1. Updating to latest version.")
		# Convert filter data from pose to an Array.
		for filter in filterData: # upper, bottom, face...
			if typeof(filterData[filter]) == TYPE_ARRAY:
				break
			filterData[filter] = filterData[filter].keys()
		has_updated = true
	if _version_is_older_than([0,9,2]):
		print("[posepal] Poselib older than 0.9.2. Updating to latest version.")
		# Convert all nodepath references to nodepath ids.
		for template in poseData.keys():
			for collection in poseData[template].keys():
				for pose_id in poseData[template][collection].size():
					var pose: Dictionary = poseData[template][collection][pose_id]
					for nodepath in pose.keys():
						if typeof(nodepath) == TYPE_INT:
							break
						var np_id: int = get_id_from_nodepath(nodepath)
						pose[np_id] = pose[nodepath]
						pose.erase(nodepath)
		has_updated = true
	if has_updated:
		poselib_version = latest_version
		print('[posepal] Poselib succesfully updated to ',poselib_version)
	
func _version_is_older_than(check_version: PoolIntArray):
	if poselib_version[0] > check_version[0]: # MAJOR
		return false
	if poselib_version[1] > check_version[1]: # MINOR
		return false
	if poselib_version[2] >= check_version[2]: # PATCH
		return false
	return true
