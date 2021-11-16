tool
extends VBoxContainer

const TEX_IconValid: StreamTexture = preload("res://addons/posepal/assets/icons/icon_yes.png")
const TEX_IconInvalid: StreamTexture = preload("res://addons/posepal/assets/icons/icon_not.png")
const TEX_IconPartial: StreamTexture = preload("res://addons/posepal/assets/icons/icon_maybe.png")
const TEX_IconWaiting: StreamTexture = preload("res://addons/posepal/assets/icons/icon_more.png")

enum ValidState {
	INVALID
	VALID
	PARTIAL # Toolhint shows what nodes are invalid
	WAITING # InactiveTimer still waiting
}
var valid_state: int = ValidState.INVALID setget _set_valid_state

func _ready() -> void:
	var lineEdit: LineEdit = $HBox/LineEdit
	$"Button".connect("pressed", self, "_on_pressed")
	$InactivityTimer.connect("timeout", self, "_on_InactivityTimer_timeout")
	lineEdit.connect("text_changed", self, "_on_text_changed")
	lineEdit.connect("text_entered", self, "_on_text_entered")
	$HBox/ValidityIcon.connect("pressed", self, "_on_ValidityIcon_pressed")



func confirm_property(text: String):
	if valid_state == ValidState.INVALID:
		return
	if valid_state == ValidState.WAITING:
		$InactivityTimer.stop()
		_check_validity()
	var propertyBox: VBoxContainer = $"../HSplitContainer/PropertyScroll/VBox"
		
	for propertyDisplay in propertyBox.get_children():
		var propertyContainer: Control = propertyDisplay.get_node("PropertyContainer")
		for propertyItem in propertyContainer.get_children():
			if propertyItem.property == text:
				continue
		if propertyDisplay.is_valid_for_batch_property:
			propertyDisplay.add_propertyItem(text)
	$"HBox/LineEdit".text = ""
	self.valid_state == ValidState.INVALID

func _check_validity():
	# Check validity of property in all nodes.
	var propertyBox: VBoxContainer = $"../HSplitContainer/PropertyScroll/VBox"
	
	var new_property: String = $HBox/LineEdit.text
	
	var valid_nodepaths: PoolStringArray
	var invalid_nodepaths: PoolStringArray
	for propertyDisplay in propertyBox.get_children():
		if new_property in propertyDisplay.node:
			var is_duplicate: bool = false
			var propertyContainer: Control = propertyDisplay.get_node("PropertyContainer")
			for propertyItem in propertyContainer.get_children():
				if propertyItem.property == new_property:
					is_duplicate = true
					break
			
			if !is_duplicate:
				valid_nodepaths.append(propertyDisplay.node_nodepath)
			propertyDisplay.is_valid_for_batch_property = true
		else:
			invalid_nodepaths.append(propertyDisplay.node_nodepath)
			propertyDisplay.is_valid_for_batch_property = false
	if invalid_nodepaths.size() > 0 && valid_nodepaths.size() > 0:
		self.valid_state = ValidState.PARTIAL
	elif valid_nodepaths.size() > 0 && invalid_nodepaths.size() == 0:
		self.valid_state = ValidState.VALID
	else:
		self.valid_state = ValidState.INVALID
	
	
	

func _set_valid_state(new_valid_state: int):
	valid_state = new_valid_state
	var validityIcon: TextureButton = $"HBox/ValidityIcon"
	match valid_state:
		ValidState.WAITING:
			validityIcon.texture_normal = TEX_IconWaiting
			
			var propertyBox: VBoxContainer = $"../HSplitContainer/PropertyScroll/VBox"
			for propertyDisplay in propertyBox.get_children():
				propertyDisplay.is_valid_for_batch_property = false
			
		ValidState.INVALID:
			validityIcon.texture_normal = TEX_IconInvalid
		ValidState.VALID:
			validityIcon.texture_normal = TEX_IconValid
		ValidState.PARTIAL:
			validityIcon.texture_normal = TEX_IconPartial
		

func _on_text_entered(new_text: String):
	confirm_property(new_text)
	
func _on_pressed():
	confirm_property($HBox/LineEdit.text)

func _on_text_changed(new_text: String):
	# Timer of few seconds until no change was made.
	var inactivityTimer: Timer = $InactivityTimer
#	print(inactivityTimer.time_left)
	inactivityTimer.start(2)
	if valid_state != ValidState.WAITING:
		self.valid_state = ValidState.WAITING
#	print(inactivityTimer.time_left)
	
func _on_InactivityTimer_timeout():
	_check_validity()

func _on_ValidityIcon_pressed():
	$InactivityTimer.stop()
	_check_validity()
