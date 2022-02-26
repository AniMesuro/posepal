tool
extends Resource

#########  EXAMPLE TEMPLATE   #########
#filterData: {# Stores direct poses
#	'none': null # Serves only as a tag to ignore filters.
#	'head': { # Filter poses are called by names instead of ids.
#		"TTorso/Head": {}
#		
#		
#	}
#PoseData: { # Stores collections
#	'default': { # Stores subcollections
#		'default': [ # Stores Poses
#			{ -- [0] Pose ID = position in array
#				"_name": 'idle' -- custom pose name
#				"TTorso/TArm/Barm": { -- NodePath from scene owner
#					"rotation_degrees": { -- Property path
#						"val": 180 --  Value of key
#						"out": .7 -- Transition of current key
#						"in": 0 -- Transition of previous key
#					}
#				},
#				"Head/Eyes": { -- NodePath from scene owner
#					"texture": { -- Property path
#						"val": "res://assets/example_rig/head/eyes_open_left.png" -- Value of key
#						"out": 0 -- Transition doesn't matter as texture can't interpolate
#						"in": 0 -- Transition doesn't matter as texture can't interpolate
#					}
#				}
#			}
#		]
#	} 
#}
#########  TEMPLATE   #########

# Scene path
export var owner_filepath: String = "res://"

enum ReferenceType {
	PATH,
	RESOURCE
}
export var resourceReferences: Dictionary = {} # Node shortcuts ex. {0: ["/Head/Eyes", SttreamTexture:1234]]}
# poses should store shortcuts instead of nodepaths so it's safe from node modification.

export var poseData: Dictionary = {"default": {"default": []}}
export var filterData: Dictionary = {"none": {}}
export var templateData: Dictionary = {"default": {}}
#export var resourceReferences: Array = []
var filtered_pose_ids: Array = [] # [0,3,6,12,13] shows the pose_ids visible within filters.


func _init() -> void:
	print(self,' poselib created.')
	prepare_loading_resourceReferences()
	# <TODO> Check if all paths in scene_nodes are valid.
#	var poseRoot: Node
#	var undefined_shortcuts: Array = []
#	for shortcut in scene_shortcuts:
#		var nodepath: String = scene_shortcuts[shortcut]
#
#		if !is_instance_valid(poseRoot.get_node_or_null(nodepath)):
#			undefined_shortcuts.append(shortcut)
	# Show popup for user to select the new path for each node,
	# allowing only for nodes with same class.
	# also allowing for user to create nodes with appropriate type if necessary.

#func save_lib(poselib_filepath: String):
#	ResourceSaver.save(poselib_filepath, self)
#
#
#
#func load_lib(poselib_filepath: String):
#	ResourceLoader.load(poselib_filepath)

# Resources don't track dependency, so it'll store only paths again.
func prepare_loading_resourceReferences():
	print('preparing exts')
#	yield()
	for i in resourceReferences.size():
		var path: String = resourceReferences[i][ReferenceType.PATH]
		var res: String = resourceReferences[i][ReferenceType.RESOURCE]
		print(path)
		
		if ResourceLoader.exists(path):
			resourceReferences[i].resize(2)
			resourceReferences[i][ReferenceType.RESOURCE] = ResourceLoader.load(path)
#			print(resourceReferences[i][2])
	print(resourceReferences)

func prepare_saving_resourceReferences():
	# Delete all actual resource references.
	for i in resourceReferences.size():
		resourceReferences[i].resize(2)
#
#func prepare_to_load():
#	pass

func clear():
	owner_filepath = "res://"
	poseData = {"default": {"default": []}}
	filterData = {"none": {}}
	templateData = {"default": {}}

func get_res_from_id(id: int):
	if resourceReferences.size() <= id:
		return null
	return resourceReferences[id][ReferenceType.RESOURCE]

func get_id_from_path(path: String):
	var res_pairs: Array = resourceReferences.values()
	for i in res_pairs.size():
		var res_pair = res_pairs[i]
		if res_pair[ReferenceType.PATH] == path:
			return i

func get_id_from_res(res: Resource):
	var res_pairs: Array = resourceReferences.values()
	for i in res_pairs.size():
		var res_pair = res_pairs[i]
		if res_pair[i][ReferenceType.RESOURCE] == res:
			return i
	var id = resourceReferences.size()
	resourceReferences[id] = [res.resource_path, res]
	print('get_ext_id ',resourceReferences)
	return id;

#func store_pose(pose_key: String):
#	poseData
