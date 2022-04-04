tool
extends HBoxContainer

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var current_page: int = -1 setget _set_current_page
var page_count: int = -1
var page_size: int = 9 # Quantity of poses per page.

func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	
	$FirstButton.connect("pressed", self, "_on_FirstButton_pressed")
	$LastButton.connect("pressed", self, "_on_LastButton_pressed")
	$PreviousButton.connect("pressed", self, "_on_PreviousButton_pressed")
	$NextButton.connect("pressed", self, "_on_NextButton_pressed")

func _set_current_page(new_current_page: int):
	current_page = new_current_page
	var numButton: OptionButton = $NumButton
	
	if new_current_page == -1:
		return
	$"../../ScrollContainer/GridContainer".fill_previews()

func _on_FirstButton_pressed():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	self.current_page = 0

func _on_LastButton_pressed():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	self.current_page = page_count-1

func _on_PreviousButton_pressed():
	if current_page -1 > -1:
		self.current_page -= 1

func _on_NextButton_pressed():
	if current_page + 1 < page_count:
		self.current_page += 1

func update_NumButton_item_list():
	var poselib: RES_PoseLibrary = owner.current_poselib
	var numButton: OptionButton = $NumButton
	if poselib.poseData.size() == 0:
		page_count = -1
		current_page = -1
		return
	var poselib_pagecount: int = ceil(poselib.poseData.size()/9)
	
	if numButton.get_item_count() != poselib_pagecount:
		numButton.clear()
		page_count = poselib_pagecount-1 
		if current_page > poselib_pagecount:
			current_page = page_count
			numButton.text = numButton.get_item_text(current_page)
		for page in poselib_pagecount:
			numButton.add_item(str(page))

func _reset_info():
	page_count = -1
	current_page = -1

func update_pages():	
	get_page_count()
	
	var numButton: OptionButton = $NumButton
	numButton.update_item_list()
	if current_page > -1 && current_page < page_count:
		numButton.select(current_page)

func get_page_count() -> int:
	var poselib: RES_PoseLibrary = owner.current_poselib
	if poselib.poseData.size() == 0:
		_reset_info()
		return -1
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return -1
	var collection: Array = poselib.poseData[owner.poselib_template][owner.poselib_collection]
	var pose_count: int = collection.size()
	if pose_count == 0:
		_reset_info()
		return -1
	page_count = ceil(float(pose_count) / page_size)
	return page_count
