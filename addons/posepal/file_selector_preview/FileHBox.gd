tool
extends HBoxContainer

var all_filters_option: String = "* All Images"

func _ready() -> void:
	var extensionMenu: MenuButton = $ExtensionMenu
	
	$LineEdit.connect("text_entered", self, "_on_text_entered")
	extensionMenu.get_popup().connect("id_pressed", self, "_on_ExtensionMenuPopup_id_pressed")
	extensionMenu.get_popup().clear()
	extensionMenu.get_popup().add_item(all_filters_option)
	extensionMenu.text = all_filters_option
#	print(owner.current_filter)
	
func update_extensions():
	var extensionMenu: MenuButton = $ExtensionMenu
	extensionMenu.get_popup().clear()
	for extension in owner.filters:
		extensionMenu.get_popup().add_item(extension)
	extensionMenu.get_popup().add_item(all_filters_option)
	extensionMenu.text = owner.current_filter
#	extensionMenu.text = all_filters_option

func _on_text_entered(new_text :String):
	var Dir: Directory = Directory.new()
	var fileContainer: GridContainer = $"../FilePanel/ScrollContainer/FileContainer"
	
	if owner.mode == FileDialog.MODE_OPEN_FILE:
		if Dir.file_exists(owner.current_dir + new_text):
			if new_text.get_extension() in owner.filters:
				owner.current_file = new_text
				
				for fileIcon in fileContainer.get_children():
					if fileIcon.file_name == owner.current_file:
						fileContainer.selectedFileIcon = fileIcon
						break
		else:
			$LineEdit.text = owner.current_file
	elif owner.mode == FileDialog.MODE_SAVE:
		if new_text.get_extension() == '':
			if owner.current_filter != '*':
				new_text = new_text+'.'+owner.current_filter
				$LineEdit.text = owner.current_file

func _on_ExtensionMenuPopup_id_pressed(id :int):
	var popupMenu = $ExtensionMenu.get_popup()
	
	var selected_filter :String= popupMenu.get_item_text(id)
	if selected_filter == all_filters_option:
		owner.current_filter = "*"
		$ExtensionMenu.text = all_filters_option
		return
	elif selected_filter in owner.filters:
		owner.current_filter = selected_filter
#		$ExtensionMenu.text = selected_filter
