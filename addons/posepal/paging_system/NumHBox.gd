tool
extends HBoxContainer

#const SCN_PageNumButton: PackedScene = preload("res://addons/posepal/paging_system/PageNumButton.tscn")
#"res://addons/posepal/paging_system/PageNumButton.gd"
var selectedPageButton: Button = null setget _set_selectedPageButton

var pageHBox: HBoxContainer setget ,_get_pageHBox

func _ready() -> void:
	if get_tree().edited_scene_root == owner:
		return
#	connect("resized", self, "_on_resized")
	owner.connect("resized", self, "_on_dock_resized")

func _on_dock_resized():
	# Fill entire space with buttons.
#	fill_pages()
#	var pageHBox: HBoxContainer = get_parent()
#	if get_children().size() == 0:
#		return
#	var lastButton: Button = get_children()[-1]
#	var dock_end: float = (owner.rect_global_position.x +  owner.rect_size.x )
#	print("dock pos+size ",(owner.rect_global_position.x +  owner.rect_size.x), " end ",rect_)
#	if (lastButton.rect_global_position.x + lastButton.rect_size.x + 28) > dock_end:
#	if (self.pageHBox.rect_global_position.x + self.pageHBox.rect_size.x) > dock_end:
#	owner.rect_size = owner.rect_min_size
	fill_pages()
#		lastButton.free()
#	else:
#		print('lastbutton survived')

#func _on_resized():
#	print('numhbox resized')
#	var lastButton: Button = get_children()[-1]
#	if (lastButton.rect_global_position.x + lastButton.rect_size.x) > (owner.rect_global_position.x +  owner.rect_size.x):
#		lastButton.queue_free()
#	else:
#		print('lastbutton survived')

func select_page(page_id: int):
	var pageHBox: HBoxContainer = get_parent()
	if is_instance_valid(selectedPageButton):
		if selectedPageButton.page_id == page_id:
			return
	
	if page_id < 0:
		return
	if page_id > pageHBox.last_page:
		return
	
	for child in get_children():
		if child.page_id == page_id:
			pageHBox.current_page = page_id
			self.selectedPageButton = child
			return

func _set_selectedPageButton(new_selectedPageButton: Button):
	if selectedPageButton == new_selectedPageButton:
		return
	
	if is_instance_valid(selectedPageButton):
		selectedPageButton.is_current = false
	new_selectedPageButton.is_current = true
	selectedPageButton = new_selectedPageButton

var _last_max_buttons_visible: int = -1
func fill_pages():
	return
	# numbutton minsize is 8,8
#	rect_size = Vector2()
#	var dock_xend: float = (owner.rect_global_position.x + owner.rect_size.x)
#	var pageHBox: HBoxContainer = get_parent()
#	var pageHBox_xend: float = pageHBox.rect_global_position.x + 60 + rect_size.x
#	var error_margin: float = pageHBox_xend - dock_xend
#	var max_buttons_visible: int = floor(rect_size.x/22)
#	var endx
#	print('maxbuttons ',max_buttons_visible)
#	if _last_max_buttons_visible == max_buttons_visible:
#		return
#	print('filling pages')
#	var current_page: int = pageHBox.current_page
#	for child in get_children():
#		child.free()
##	yield(get_tree(), "idle_frame")
##	var offset: int = pageHBox.current_page - 2
##	var offset: int = pageHBox.last_page - pageHBox.current_page
#	var offset: int = clamp(current_page - floor(max_buttons_visible/2), 1, pageHBox.last_page)
#	print('page offset ',offset)
#	var current_dock_size : Vector2 = owner.rect_size
#	for i in max_buttons_visible:
#		if rect_global_position.x+ i*20 > dock_xend-10:
#			print('####')
#			break
##		if pageHBox_xend  > dock_xend:
##			print(i,' page is outside bounds')
##			return
#		var button: Button = SCN_PageNumButton.instance()
#		add_child(button)
#		button.page_id = offset + i # + offset
#	if current_dock_size != owner.rect_size:
#	_on_dock_resized()

#func _clips_input() -> bool:
#	print('_clips_input')
##	for child in get_children():
##		var btn: Button = child
##		if btn.rect_position.x + btn.rect_size.x > rect_size.x:
##			btn.queue_free()
##			return true
#	return true

func _get_pageHBox() -> HBoxContainer:
	if !is_instance_valid(pageHBox):
		pageHBox = get_parent()
	return pageHBox
