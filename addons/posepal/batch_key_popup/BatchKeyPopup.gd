tool
extends Popup


const TEX_Icon: StreamTexture = preload("res://addons/posepal/plugin_icon.png")
#onready var itemTree: Tree = $"MarginContainer/VBox/HSplitContainer/ScrollContainer2/Tree"

var handlerTop :ReferenceRect
var handlerBottom :ReferenceRect
var handlerLeft :ReferenceRect
var handlerRight :ReferenceRect

var current_edited_animPlayer: AnimationPlayer setget _set_current_edited_animPlayer

var pluginInstance: EditorPlugin setget ,_get_pluginInstance
var editorControl: Control setget ,_get_editorControl

var posepalDock: Control
func _enter_tree() -> void:
	show()
	visible = true

func _ready() -> void:
	# Load scene tree on nodeVBox
	pass

func _get_pluginInstance() -> EditorPlugin:
	if is_instance_valid(pluginInstance):
		return pluginInstance
	if get_tree().get_nodes_in_group("plugin posepal").size() == 0:
		queue_free()
		return null
	pluginInstance = get_tree().get_nodes_in_group("plugin posepal")[0]
	return pluginInstance

func _get_editorControl() -> Control:
	if is_instance_valid(editorControl):
		return editorControl
	return self.pluginInstance.get_editor_interface().get_base_control()

func _set_current_edited_animPlayer(new_current_edited_animPlayer: AnimationPlayer):
	current_edited_animPlayer = new_current_edited_animPlayer
	if !is_inside_tree():
		return
	if !is_instance_valid(current_edited_animPlayer):
		return
	var titleBar: HBoxContainer = $"MarginContainer/VBox/TitleBar"
	titleBar.title_name = "Batch key to: "+ new_current_edited_animPlayer.name+ " / "+ new_current_edited_animPlayer.assigned_animation
