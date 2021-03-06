tool
extends HBoxContainer

func _ready() -> void:
	$OkButton.connect("pressed", self, "_on_OkButton_pressed")
	$CancelButton.connect("pressed", self, "_on_CancelButton_pressed")

func _on_OkButton_pressed():
	var propertyBox: VBoxContainer = $"../HSplitContainer/PropertyScroll/VBox"
	var editedSceneRoot: Node = get_tree().edited_scene_root
	var poseSceneRoot: Node = editedSceneRoot.get_node(owner.posepalDock.poselib_scene)
	var currentAnimOptionButton: OptionButton = owner.pluginInstance.animationPlayerEditor_CurrentAnimation_OptionButton
	var currentTimeLineEdit: LineEdit = owner.pluginInstance.animationPlayerEditor_CurrentTime_LineEdit
	var editorInterface: EditorInterface = owner.pluginInstance.get_editor_interface()
	var editorSelection: EditorSelection = editorInterface.get_selection()
	var animPlayer: AnimationPlayer = owner.current_edited_animPlayer
	if !is_instance_valid(animPlayer):
		print('[posepal] AnimationPlayer not valid.')
		return
		
	var anim: Animation = animPlayer.get_animation(currentAnimOptionButton.text)
	var animRoot: Node = animPlayer.get_node(animPlayer.root_node)
	
	var current_time: float = float(currentTimeLineEdit.text)
	for propertyDisplay in propertyBox.get_children():
		var node = propertyDisplay.node
		for property in propertyDisplay.get_properties():
			var property_path: String = str(animRoot.get_path_to(node))+':'+property
			var tr_property: int = anim.find_track(property_path)
			
			var key_value = node.get(property)
			if tr_property == -1:
				tr_property = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(tr_property, property_path)
				var update_mode: int = owner.posepalDock.get_default_update_mode(property, key_value)
				anim.value_track_set_update_mode(tr_property, update_mode)
			
			anim.track_insert_key(tr_property, current_time, key_value)
	owner.queue_free()

func _on_CancelButton_pressed():
	owner.queue_free()


