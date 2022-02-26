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

export var scene_shortcuts: Dictionary = {} # Node shortcuts ex. {0:"/Head/Eyes"}
# poses should store shortcuts instead of nodepaths so it's safe from node modification.

export var poseData: Dictionary = {"default": {"default": []}}
export var filterData: Dictionary = {"none": {}}
export var templateData: Dictionary = {"default": {}}
export var external_resources: Array = []
var filtered_pose_ids: Array = [] # [0,3,6,12,13] shows the pose_ids visible within filters.


func _init() -> void:
	print(self,' poselib created.')
	prepare_loading_external_resources()
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
func prepare_loading_external_resources():
	print('preparing exts')
#	yield()
	for i in external_resources.size():
		var ext_path: String = external_resources[i][0]
		var ext_type: String = external_resources[i][1]
		print(ext_path)
		
		if ResourceLoader.exists(ext_path, ext_type):
			external_resources[i].resize(3)
			external_resources[i][2] = ResourceLoader.load(ext_path, ext_type)
			print(external_resources[i][2])
	print(external_resources)

func prepare_saving_external_resources():
	# Delete all actual resource references.
	for i in external_resources.size():
		external_resources[i].resize(2)
#
#func prepare_to_load():
#	pass

func clear():
	owner_filepath = "res://"
	poseData = {"default": {"default": []}}
	filterData = {"none": {}}
	templateData = {"default": {}}

func get_ext_resource(id: int):
	if external_resources.size() <= id:
		return null
	return external_resources[id][2]

func get_ext_id(res: Resource):
	for i in external_resources.size():
		var ext: Array = external_resources[i]
		if res.resource_path == ext[0]:
			return i
	external_resources.append([res.resource_path, res.get_class(), res])
	var id = external_resources.size()
	print('get_ext_id ',external_resources)
	return id;

#func store_pose(pose_key: String):
#	poseData
