tool
extends HBoxContainer

const TEX_IconValid :StreamTexture= preload("res://addons/pose library/assets/icons/icon_yes.png")
const TEX_IconInvalid :StreamTexture= preload("res://addons/pose library/assets/icons/icon_not.png")

var propertyContainer :VBoxContainer

var button :Button
var lineEdit :LineEdit

func _ready() -> void:
	propertyContainer = $"../Panel/ScrollContainer/PropertyContainer"
	
	lineEdit = $LineEdit
	button = $Button
	
	lineEdit.connect("text_changed", self, "_on_LineEdit_text_changed")
	lineEdit.connect("text_entered", self, "_on_LineEdit_text_entered")
	button.connect("pressed", self, "_on_Button_pressed")

func _on_LineEdit_text_changed(new_text :String):
	var nodeRef :Node= owner.nodeRef
	if !new_text in nodeRef:
		button.icon = TEX_IconInvalid
	else:
		button.icon = TEX_IconValid

func _on_LineEdit_text_entered(new_property :String):
	add_property(new_property)

func _on_Button_pressed():
	add_property(lineEdit.text)

func add_property(new_property :String):
	#Checks if pose node has property.
	var nodeRef :Node= owner.nodeRef
	if new_property in nodeRef:
#		if nodeRef.get(new_property) is Resource:
#			print(new_property," is Resource")
##			var poseScene :Node= owner.get_parent().poseSceneRoot
#			var nodepath :String= owner.node_nodepath#poseScene.get_path_to(nodeRef)
#			if !owner.get_parent().jsonPose.has(nodepath):
#				owner.get_parent().jsonPose[nodepath] = {}
#			owner.get_parent().jsonPose[nodepath][new_property] = nodeRef.get(new_property).resource_path
#			print('jsonPose =',owner.get_parent().jsonPose)
		
		propertyContainer.add_property(new_property)
		
		print('pose = ',owner.pose)
	
	lineEdit.text = ""
