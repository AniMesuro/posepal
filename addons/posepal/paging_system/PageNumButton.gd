tool
extends OptionButton

var pageHBox: HBoxContainer
func _ready() -> void:
	pageHBox = $".."
	connect("item_selected", self, "_on_item_selected")
	connect("pressed", self, "_on_pressed")

func _on_item_selected(id: int):
	pageHBox = $'..'
	pageHBox.current_page = id

func _on_pressed():
	var poselib: Resource = owner.currentPoselib
	if !is_instance_valid(poselib):
		pageHBox = get_parent()
		pageHBox._reset_info()
		text = '-1'
		return
	
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return	

func update_item_list():
	pageHBox = get_parent()
	clear()
	for i in pageHBox.page_count:
		add_item(str(i))
