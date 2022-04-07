tool
extends HBoxContainer

func _ready() -> void:
	$OkButton.connect("pressed", self,"_on_OkButton_pressed")
	$CancelButton.connect("pressed", self, "_on_CancelButton_pressed")

func _on_OkButton_pressed():
	var Dir: Directory = Directory.new()
	var filepath: String = owner.current_dir + owner.current_file
	if owner.mode == FileDialog.MODE_OPEN_FILE:
		if Dir.file_exists(filepath):
			owner.emit_signal("file_selected", filepath)
	elif owner.mode == FileDialog.MODE_SAVE_FILE:
		if !Dir.file_exists(filepath):
			owner.emit_signal("file_selected", filepath)
		else:
			# [] REPLACE WITH "Are you sure to overwite?" POPUP
			owner.emit_signal("file_selected", filepath)
	else:
		print('FileSelectorPreview: Mode not supported.')
	owner.queue_free()
"res://addons/posepal/file_selector_preview/FileIcon.gd"
func _on_CancelButton_pressed():
	owner.queue_free()
