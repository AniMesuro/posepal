tool
extends HBoxContainer

func _ready() -> void:
	$OkButton.connect("pressed", self, "_on_OkButton_pressed")
	$CancelButton.connect("pressed", self, "_on_CancelButton_pressed")

func _on_OkButton_pressed():
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.posepalDock.poselib_scene)
	var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	print('selected ',editorSelection.get_selected_nodes())

func _on_CancelButton_pressed():
	owner.queue_free()

