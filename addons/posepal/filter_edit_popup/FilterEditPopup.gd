tool
extends WindowDialog

var posepalDock: Control

func _enter_tree() -> void:
	show()

func _ready() -> void:
	var okButton: Button = $Margin/VBox/OkButton
	okButton.connect("pressed", self, "_on_OkButton_pressed")
	
func _on_OkButton_pressed():
	queue_free()


