#tool
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
var owner_filepath: String = "res://"

export var scene_shortcuts: Dictionary = {} # Node shortcuts ex. {0:"/Head/Eyes"}
# poses should store shortcuts instead of nodepaths so it's safe from node modification.

export var poseData: Dictionary = {"default": {"default": []}}
export var filterData: Dictionary = {"none": {}}
export var templateData: Dictionary = {"default": {}}
var filtered_pose_ids: Array = [] # [0,3,6,12,13] shows the pose_ids visible within filters.

func _init() -> void:
	print(self,' poselib created.')
	
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

func clear():
	owner_filepath = "res://"
	poseData = {"default": {"default": []}}
	filterData = {"none": {}}
	templateData = {"default": {}}


#func store_pose(pose_key: String):
#	poseData
