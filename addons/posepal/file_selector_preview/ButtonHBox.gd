tool
extends HBoxContainer

func _ready() -> void:
	$OkButton.connect("pressed", self,"_on_OkButton_pressed")
	$CancelButton.connect("pressed", self, "_on_CancelButton_pressed")

func _on_OkButton_pressed():
	var Dir :Directory= Directory.new()
	var filepath :String= owner.current_dir + owner.current_file
	if Dir.file_exists(filepath):
		owner.emit_signal("file_selected", filepath)
	owner.queue_free()

func _on_CancelButton_pressed():
	owner.queue_free()
