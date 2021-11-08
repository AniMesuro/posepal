tool
extends HBoxContainer

const RES_PoseLibrary: GDScript = preload("res://addons/posepal/PoseLibrary.gd")

var current_page: int = -1 setget _set_current_page
var last_page: int = -1

func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
	
	$FirstButton.connect("pressed", self, "_on_FirstButton_pressed")
	$LastButton.connect("pressed", self, "_on_LastButton_pressed")

func _set_current_page(new_current_page: int):
	if current_page == new_current_page:
		return
	
	current_page = new_current_page
	var numButton: OptionButton = $NumButton
	
	# Select new current_page
	
	# <TODO> -- Fill itemMenu with all possible pages if not yet
	if !numButton.get_item_count() > new_current_page:
		numButton.update_item_list()
	#_update_NumButton_item_list()
	print('pagecnt ',numButton.get_item_count())
	numButton.select(new_current_page)

func _on_FirstButton_pressed():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
	
#	_update_NumButton_item_list()
#	var numHBox: HBoxContainer = $"NumHBox"
#	numHBox.fill_pages()
	self.current_page = 0

func _on_LastButton_pressed():
	var poselib: RES_PoseLibrary = owner.current_poselib
	if !is_instance_valid(poselib):
		return
		
#	_update_NumButton_item_list()
#	var last_page: int = poselib.poseData.size()-1
#	if last_page < 0:
#		return
	self.current_page = last_page

func _update_NumButton_item_list():
	var poselib: RES_PoseLibrary = owner.current_poselib
	var numButton: OptionButton = $NumButton
	if poselib.poseData.size() == 0:
		last_page = -1
		current_page = -1
		return
#	var numButtom_count: int = 
	var poselib_pagecount: int = ceil(poselib.poseData.size()/9)
	
	if numButton.get_item_count() != poselib_pagecount:
		# Unoptimized
		# Tbh is kinda stupid because it only needs to be updated when clicked.
		numButton.clear()
		
		last_page = poselib_pagecount-1 # Only updated when page changes
		if current_page > poselib_pagecount:
			current_page = last_page
			numButton.text = numButton.get_item_text(current_page)
			
		for page in poselib_pagecount:
			numButton.add_item(str(page))
			
			
			

