tool
extends VBoxContainer

const SCN_PropertyOption :PackedScene= preload("res://addons/posepal/new_pose_popup/property_display/PropertyOption.tscn")

func fill_properties():
	clear_properties()
	for property in owner.pose[owner.node_nodepath]:
		var propertyOption :HBoxContainer= SCN_PropertyOption.instance()
		add_child(propertyOption)
		propertyOption.pose_property = property
		propertyOption.connect("requesting_property_removal", self, "remove_property")

func clear_properties():
	for propertyOption in get_children():
		propertyOption.queue_free()

func add_property(new_property :String):
	# Assumes property is from node.
	var nodeRef :Node= owner.nodeRef
	owner.pose[owner.node_nodepath][new_property] = nodeRef[new_property]
	fill_properties()

func remove_property(property :String):
	# Remove from JsonPose if value is there as well.
#	if owner.get_parent().jsonPose.has(owner.node_nodepath):
#		if owner.get_parent().jsonPose[owner.node_nodepath].has(property):
#			owner.get_parent().jsonPose[owner.node_nodepath].erase(property)
			
	owner.pose[owner.node_nodepath].erase(property)
	fill_properties()
	
