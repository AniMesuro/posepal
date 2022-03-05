tool
extends HBoxContainer

func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	owner.connect('updated_reference', self, '_on_PoseLibrary_updated_reference')

func _on_PoseLibrary_updated_reference(reference :String):
	if reference != 'poselib_animPlayer':
		return
	if is_instance_valid(owner.get('poselib_animPlayer')):
		var editorInterface :EditorInterface= owner.pluginInstance.get_editor_interface()
		var editorSelection :EditorSelection= editorInterface.get_selection()
		editorSelection.clear()
		editorSelection.add_node(owner.get('poselib_animPlayer'))
		owner.fix_warning('animplayer_invalid')
