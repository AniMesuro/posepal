tool
extends Resource

# Please do not change poselib files manually (unless for debugging)
# Try to update it from the dock if possible.
# ------------

# Scene path
export var owner_filepath: String = "res://"

enum ReferenceType {
	PATH,
	RESOURCE
}
export var resourceReferences:  Dictionary = {} # Resource path ref ex. {0: "res://eyes.png"}
var resourceReferences_res: 	Dictionary = {} # Resource ref ex. {0: [StreamTexture:1234]}
export var available_res_id: int = 0
var is_references_valid: bool = true

export var poseData: Dictionary = {"default": {"default": []}}
export var filterData: Dictionary = {"none": {}}
export var templateData: Dictionary = {"default": {}}

var filtered_pose_ids: Array = [] # [0,3,6,12,13] shows the pose_ids visible within filters.

func setup():
	prepare_loading_resourceReferences()

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
