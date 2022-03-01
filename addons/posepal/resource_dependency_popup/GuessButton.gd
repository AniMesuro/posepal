tool
extends Button

func _ready() -> void:
	connect("pressed", self, "_on_pressed")
	
#	disabled = false

# Currently this button only works if user selects the first 
func _on_pressed():
	var poselib: Resource = owner.posePalDock.current_poselib
	var fileVBox: VBoxContainer = $"../VBox/ScrollCon/FileVBox"
	var f: File = File.new()
	
	#Check if user fixed the first dependency,
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
		print("Couldn't guess because no similar dirs were found.")
		return
#	print('path fixes: ',dir_fixes)
#	print('unfixed children: ',fileItems_unfixed)
#	var first_path: String = fileVBox.get_child(0).new_path
#	if !f.file_exists(first_path):
#		return
#	var first_old_path: String = fileVBox.get_child(0).old_path
#	var first_subpaths: PoolStringArray = first_path.split('/', false)
	
	var unique_old_dirs: Array = [] # ['res://head/', 'res://torso/', 'res://bottom/']
	var unique_old_ids: Array = [] # [[0,1,2], [3,4], [5,6]] - paralel to unique_old_dirs
	for i in owner.old_paths.size():
		var old_path: String = owner.old_paths[i]
		var old_dir: String = old_path.get_base_dir()
		var sib_id: int = unique_old_dirs.find(old_dir)
		if sib_id != -1:#unique_old_dirs.has(old_dir):
			unique_old_ids[sib_id].append(i)
		else:
			unique_old_dirs.append(old_dir)
			unique_old_ids.append([i])
#	print('unique old ',unique_old_dirs,'\n',unique_old_ids)
	
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
			var fileItem: HBoxContainer = fileItems_unfixed[k]
#			print('pure name ', fileItem.pure_name)
			var new_path: String = fixed_dir+fileItem.pure_name
#			print('new_path: ',new_path)
			if f.file_exists(new_path):
				fileItem.new_path = new_path
#				print('exists')
	return
		
#		for res_id in siblings:
#	for fileItem in fileItems_unfixed:
#		for siblings_id in unique_old_ids: 
#			var siblings: Array = unique_old_ids[siblings_id]
#			if !siblings.has(fileItem.res_id):
#				continue
#			for i in dir_fixes.keys():
#				if !i in siblings:
#					continue
					
		
		
	
	
#	for i in unique_old_ids.size():
#		var dir_ids: Array = unique_old_ids[i]
#		var dir: String = unique_old_dirs[i]
#
#		print(i,' ',dir_ids,' ',dir)
#
	
	
#	var shared_path: String = ''
#	var shared_at: int = 0
	
#	var owner_path: String = poselib.owner_filepath.get_base_dir()
#	var owner_subpaths: PoolStringArray = owner_path.split('/', false)
#	owner_subpaths[0]+='/'
##	print(owner_path,'\n', string_array_to_string(owner_subpaths, '/'))
#	print('owner path ',owner_path)
#	print('first path')
	
	# New dir inside owner_path
#	var nesting_difference: int = first_subpaths.size() - owner_subpaths.size()
#	if nesting_difference > 0: # first_path inside owner_path
#		for i in nesting_difference:
#			print(str(first_subpaths[first_subpaths.size()-(nesting_difference-i)]))
	
	
	
	
#	for i in owner.old_paths.size():
#		var old_path: String = owner.old_paths[i]
#		var new_path = fileVBox.get_child(i).new_path
#		if f.file_exists(new_path):
#			continue
#
#		var subpaths: PoolStringArray = old_path.rsplit('/', false)
#		subpaths.remove(subpaths.size()-1)
#		var differs_at: int = 0 # res://
#		for j in subpaths.size():
#			var subpath: String = subpaths[j]
#			if owner_path_subpaths.size() <= j:
#				differs_at = j
#				break
#			if owner_path_subpaths[j] != subpath:
#				differs_at = j
#				break
#		for j in subpaths.size()-differs_at:
#			var j1: int = j+differs_at
#			var subpath: String = subpaths[j1]
#
#		print('subpaths: ',subpaths)
#		print('owner path: ',owner_path_subpaths)
#		subpaths.resize(differs_at)
#		owner_path_subpaths.resize(differs_at)
#		print('1subpaths: ',subpaths)
#		print('1owner path: ',owner_path_subpaths)
#
#
#		owner_path_subpaths[0]+='/'
#		shared_path = string_array_to_string(owner_path_subpaths,'/')
#		print(shared_path)
#
#		var dir:Directory=Directory.new()
#		if dir.open(shared_path) == OK:
#			dir.list_dir_begin(true, true)
#			var file_name = dir.get_next()
#			var directories: PoolStringArray = []
#			while file_name != '':
#				if dir.current_is_dir():
#					print(file_name,' is dir')
#					directories.append(file_name)
#				else:
#					print(file_name,' is file.')
#					print('error ',directories[1],' ',dir.change_dir(directories[1]+'/'))
#					file_name = dir.get_next()
#					print(file_name,' is file.')
#				file_name = dir.get_next()
##				return
#		shared_path
#		if d.dir_exists()
#		f.file_exists()

#func list_

func string_array_to_string(str_array: PoolStringArray, delimeter: String):
	var final_str: String = ''
	for string in str_array:
		print(delimeter)
		final_str += string+delimeter
	if final_str.length() != 0:
		final_str.erase(final_str.length(), 1)
	return final_str

