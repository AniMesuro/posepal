tool
extends Button

func _ready() -> void:
	connect("pressed", self, "_on_pressed")
	
# Currently this button only works if user selects a path for each unique directory.
func _on_pressed():
	var poselib: Resource = owner.posePalDock.current_poselib
	var fileVBox: VBoxContainer = $"../VBox/ScrollCon/FileVBox"
	var f: File = File.new()
	
	#Check if user fixed some dependency,
	if fileVBox.get_child_count() == 0:
		return
	
	var dir_fixes: Dictionary = {} # 0:'res://'
	var fileItems_unfixed: Dictionary = fileVBox.children_as_dict.duplicate(false)
	for k in fileItems_unfixed.keys():
		var fileItem = fileItems_unfixed[k]
		if fileItem.new_path == '':
			continue
		
		dir_fixes[k] = fileItem.new_path.get_base_dir()+'/'
		fileItems_unfixed.erase(k)
	if dir_fixes.size() == 0:
		print("[posepal] Couldn't guess because no similar dirs were found.")
		return
	
	var unique_old_dirs: Array = [] # ['res://head/', 'res://torso/', 'res://bottom/']
	var unique_old_ids: Array = [] # [[0,1,2], [3,4], [5,6]] - paralel to unique_old_dirs
	for k in poselib.resourceReferences.keys():
		var old_path: String = poselib.resourceReferences[k]
		var old_dir: String = old_path.get_base_dir()
		var sib_id: int = unique_old_dirs.find(old_dir)
		
		if sib_id != -1:
			unique_old_ids[sib_id].append(k)
		else:
			unique_old_dirs.append(old_dir)
			unique_old_ids.append([k])
	
	for siblings_id in unique_old_ids.size(): # ids with same directory [0,1,2]
		var siblings: Array = unique_old_ids[siblings_id]
		var fixed_dir: String = ''
		var fixed_sib_id: int = -1
		for res_id in siblings:
			if !res_id in dir_fixes.keys():
				continue
			
			fixed_dir = dir_fixes[res_id]
			fixed_sib_id = res_id
		if fixed_dir == '':
			continue
		for k in fileItems_unfixed.keys():
			var fileItem: PanelContainer = fileItems_unfixed[k]
			var new_path: String = fixed_dir+fileItem.pure_name
			
			if f.file_exists(new_path):
				fileItem.new_path = new_path
				fileItem.display_state = 2
				fileItems_unfixed.erase(k)
	if fileItems_unfixed.size() == 0:
		pass
	return

func string_array_to_string(str_array: PoolStringArray, delimeter: String):
	var final_str: String = ''
	for string in str_array:
		final_str += string+delimeter
	if final_str.length() != 0:
		final_str.erase(final_str.length(), 1)
	return final_str
