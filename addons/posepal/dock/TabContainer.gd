tool
extends TabContainer

func _ready() -> void:
	connect("tab_selected", self, "_on_tab_selected")


func _on_tab_selected(id: int):
	if id != 1: # Palette
		return
	#refresh palette
	$"Pallete/ScrollContainer/GridContainer".fill_previews()
