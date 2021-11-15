tool
extends HBoxContainer

const TEX_IconValid :StreamTexture= preload("res://addons/posepal/assets/icons/icon_yes.png")
const TEX_IconInvalid :StreamTexture= preload("res://addons/posepal/assets/icons/icon_not.png")

const SCN_PropertyItem: PackedScene = preload("res://addons/posepal/batch_key_popup/property_display/PropertyItem.tscn")

var is_property_valid: bool = false setget _set_is_property_valid

func _ready() -> void:
	$Button.connect("pressed", self, "_on_pressed")
	$LineEdit.connect("text_changed", self, "_on_text_changed")
	$LineEdit.connect("text_entered", self, "_on_text_entered")


func text_confirm(text: String):
	if !is_property_valid:
		return
	# Instance PropertyItem
	# Only if property valid on Node.
	var propertyItem: Control = SCN_PropertyItem.instance()
	var lineEdit: LineEdit = $"LineEdit"
#	print('aaaaaaa ',propertyItem.property)
	var propertyContainer: GridContainer = $"../../../PropertyContainer"
	propertyContainer.add_child(propertyItem)
	propertyItem.property = text
	lineEdit.text = ""
	self.is_property_valid = false
	

func _on_text_changed(new_text: String):
	# Check validity
	# var in node and not dupplicated
	var propertyContainer: GridContainer = $"../../../PropertyContainer"
	var is_duplicate: bool = false
	for propertyItem in propertyContainer.get_children():
		if propertyItem.property == new_text:
			is_duplicate = true
			break
			
	
	if (new_text in owner.node) && !is_duplicate:
		self.is_property_valid = true
	else: 
		self.is_property_valid = false
	

func _on_text_entered(new_text: String):
	text_confirm(new_text)

func _on_pressed():
	text_confirm($LineEdit.text)

func _set_is_property_valid(new_is_property_valid: bool):
	is_property_valid = new_is_property_valid
	if !is_inside_tree(): return
	
	if new_is_property_valid:
		$"Button".icon = TEX_IconValid
	else:
		$"Button".icon = TEX_IconInvalid
