tool
extends VBoxContainer

var updateFromTemplateButton: Button
func _ready() -> void:
	updateFromTemplateButton = $UpdateFromTemplateButton
	
	updateFromTemplateButton.connect("pressed", self, "_on_UpdateFromTemplateButton")
	

func _on_UpdateFromTemplateButton():
	pass

