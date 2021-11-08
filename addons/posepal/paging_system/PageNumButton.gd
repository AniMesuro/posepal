tool
extends OptionButton

# User will select the page from this ItemMenu 

#export var page_id: int = -1 setget _set_page_id
#export var is_current: bool = false setget _set_is_current

var pageHBox: HBoxContainer
func _ready() -> void:
	pageHBox = $".."
	connect("item_selected", self, "_on_item_selected")
	connect("pressed", self, "_on_pressed")

#func _set_page_id(new_page_id: int):
#	if page_id == new_page_id:
#		return
#
#	page_id = new_page_id
#	text = str(page_id)

#func _set_is_current(new_is_current: bool):
#	if !new_is_current:
#		modulate = Color(1,1,1)
#	else:
#		modulate = Color(1.5,1,.5)
#
#	is_current = new_is_current
	

func _on_item_selected():
	# Update pose previews.
	pass

func _on_pressed():
	var poselib: Resource = owner.current_poselib
	if !is_instance_valid(poselib):
		pageHBox.current_page = -1
		pageHBox.last_page = -1
		return
#	if poselib.poseData.size() == 0:
#		pageHBox.current_page = -1
#		pageHBox.last_page = -1
#		return
	
	# Pagecount from current subcollection.
	if !poselib.poseData.has(owner.poselib_template):
		return
	if !poselib.poseData[owner.poselib_template].has(owner.poselib_collection):
		return
	update_item_list()
	

func update_item_list():
	var poselib: Resource = owner.current_poselib
	var _page_posecount: int = poselib.poseData[owner.poselib_template][owner.poselib_collection].size()
	var poselib_pagecount: int = ceil(_page_posecount/9.0)
#	print('pose page qnt:',_page_posecount,',',poselib_pagecount)
	if get_item_count() != poselib_pagecount:
	# Tbh is kinda stupid because it only needs to be updated when clicked.
		if !is_instance_valid(pageHBox):
			pageHBox = get_parent()
		pageHBox.last_page = poselib_pagecount-1 # Only updated when page changes
		if pageHBox.current_page > poselib_pagecount:
			pageHBox.current_page = pageHBox.last_page
#			text = get_item_text(current_page)
			
		clear()
		for page in poselib_pagecount:
			add_item(str(page))
	hint_tooltip = str(poselib_pagecount)
