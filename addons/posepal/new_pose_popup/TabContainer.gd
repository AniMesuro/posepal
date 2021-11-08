tool
extends TabContainer

func _ready() -> void:
	connect("tab_selected", self, "_on_tab_selected")
	propertyDisplay = $Properties/PropertyDisplay
	treeDisplay = $Nodes/TreeDisplay

var propertyDisplay :VBoxContainer
var treeDisplay :VBoxContainer
func _on_tab_selected(tab :int):
	# If being edited.
#	print('selected tab ',tab)
	if get_tree().edited_scene_root == self:
		return
	
	
	if tab == 1: # Properties Tab
		if propertyDisplay.last_selected_nodepaths != treeDisplay.selected_nodepaths:
			propertyDisplay.last_selected_nodepaths = treeDisplay.selected_nodepaths
			
			# If node in pose{} not selected, remove node key.
			propertyDisplay.fill_tabs()
			for nodepath in propertyDisplay.pose.keys():
				if !nodepath in treeDisplay.selected_nodepaths:
					propertyDisplay.pose.erase(nodepath)
				
		
