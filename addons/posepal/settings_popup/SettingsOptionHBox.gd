tool
extends HBoxContainer

export var selected_id: int setget _set_selected_id

func _on_id_pressed(id: int):
	self.selected_id = id
	
func _set_selected_id(new_selected_id):
	selected_id = new_selected_id
	$MenuButton.text = $MenuButton.get_popup().get_item_text(selected_id)
