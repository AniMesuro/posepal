tool
extends HBoxContainer

var all_filters_option :String= "* All Images"

func _ready() -> void:
	$LineEdit.connect("text_entered", self, "_on_text_entered")
	
	var extensionMenu :MenuButton= $ExtensionMenu
	extensionMenu.get_popup().connect("id_pressed", self, "_on_ExtensionMenuPopup_pressed")
	
	extensionMenu.get_popup().clear()
	extensionMenu.get_popup().add_item(all_filters_option)
	extensionMenu.text = all_filters_option
#	owner.current_filter = "*"
	for extension in owner.filters:
		extensionMenu.get_popup().add_item(extension)

func _on_text_entered(new_text :String):
	var Dir :Directory= Directory.new()
	if Dir.file_exists(owner.current_dir + new_text):
		if new_text.get_extension() in owner.filters:
			owner.current_file = new_text
			
			for fileIcon in $"../FilePanel/ScrollContainer/FileContainer".get_children():
				if fileIcon.file_name == owner.current_file:
					$"../FilePanel/ScrollContainer/FileContainer".selectedFileIcon = fileIcon
					break
	else:
		$LineEdit.text = owner.current_file

	

func _on_ExtensionMenuPopup_pressed(id :int):
	var popupMenu = $ExtensionMenu.get_popup()
	
	var selected_filter :String= popupMenu.get_item_text(id)
	if selected_filter == all_filters_option:
		owner.current_filter = "*"
		$ExtensionMenu.text = all_filters_option
		return
	if selected_filter in owner.filters:
		owner.current_filter = selected_filter
		$ExtensionMenu.text = selected_filter
