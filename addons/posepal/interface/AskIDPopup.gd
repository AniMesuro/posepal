tool
extends Popup

signal id_settled (new_id)

var new_id: int = -1
var max_id: int = 0

onready var titlebar: HBoxContainer = $Panel/VBox/Titlebar
onready var label: Label = $Panel/VBox/Label
var parent: Node
var spinBox: SpinBox
var button: Button

func _ready() -> void:
	popup_centered(rect_min_size)
	button = $Panel/VBox/Button
	spinBox = $Panel/VBox/ValueHBox/SpinBox
	var warningIcon = $Panel/VBox/ValueHBox/WarningIcon
	
	warningIcon.visible = false
	button.connect("pressed", self, '_on_Button_pressed')
	spinBox.connect("value_changed", self, "_on_SpinBox_value_changed")
	
func _on_Button_pressed() -> void:
	spinBox = $Panel/VBox/ValueHBox/SpinBox
	new_id = clamp(spinBox.value, 0, max_id)
	
	emit_signal("id_settled", new_id)
	queue_free()

func _on_SpinBox_value_changed(value: int) -> void:
	var warningIcon = $Panel/VBox/ValueHBox/WarningIcon
	
	new_id = value
	if value > -1 && value < max_id-1:
		warningIcon.visible = false
	elif value > max_id-1:
		warningIcon.visible = true
		warningIcon.hint_tooltip = "value exceeds maximum id allowed: "+ str(max_id)
	else: # value < 0
		warningIcon.visible = true
		warningIcon.hint_tooltip = "value exceeds minimumid allowed: 0"
