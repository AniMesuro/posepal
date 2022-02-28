tool
extends VBoxContainer

const SCN_ResourceDependencyPopup: PackedScene = preload("res://addons/posepal/resource_dependency_popup/ResourceDependencyPopup.tscn") 

func _ready() -> void:
	$FileDependencyButton.connect("pressed", self, "_on_FileDependencyButton_pressed")
	

func _on_FileDependencyButton_pressed():
	var resourceDependencyPopup: Control = SCN_ResourceDependencyPopup.instance()
	resourceDependencyPopup.posePalDock = owner
	$FileDependencyButton.add_child(resourceDependencyPopup)
	


