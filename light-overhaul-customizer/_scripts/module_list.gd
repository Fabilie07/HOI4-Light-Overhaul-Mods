extends ItemList

var module_id_array = []
var module_dict = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for module_file in get_module_strings():
		rec_load_modules(uncomment_lines(module_file), 0)

# Save the ID of all modules defined in .txt files in common/units/equipment/modules in module_id_array.
func load_modules() -> void:
	for module_file_str in DirAccess.get_files_at("res://aircraft_light/common/units/equipment/modules/"):
		if module_file_str.get_extension() == "txt":
			var module_file = FileAccess.open("res://aircraft_light/common/units/equipment/modules/"+module_file_str, FileAccess.READ)
			var module_script = module_file.get_as_text()
			
			var bracket_open = 0
			var module_string = ""
			
			for i in module_script:
				if i == "{":
					bracket_open += 1
				
				if bracket_open == 1:
					module_string = module_string + i
				
				if i == "}" and bracket_open > 0:
					bracket_open -= 1
			
			for del in ["\t", "\r", "=", "{", "}", "limit", " "]:
				module_string = module_string.replace(del, "")
			
			module_id_array = module_string.split("\n", false, 0)
			var module_id_array_clean = []
			for line in module_id_array:
				var uncommented_line = ""
				for i in line:
					if i != "#":
						uncommented_line = uncommented_line + i
					else:
						break
				if uncommented_line != "":
					module_id_array_clean.append(uncommented_line)
			
			module_id_array = module_id_array_clean

func get_module_strings() -> PackedStringArray:
	var module_string_array: PackedStringArray
	
	for module_file_str in DirAccess.get_files_at("res://aircraft_light/common/units/equipment/modules/"):
		if module_file_str.get_extension() == "txt":
			var module_file = FileAccess.open("res://aircraft_light/common/units/equipment/modules/"+module_file_str, FileAccess.READ)
			var module_script = module_file.get_as_text()
			module_string_array.append(module_script)
	
	return module_string_array

func rec_load_modules(remaining_code: PackedStringArray, bracket_level: int):
	if remaining_code.size() > 0:
		if bracket_level == 0:
			if remaining_code[0].contains("equipment_modules={"):
				remaining_code.remove_at(0)
				rec_load_modules(remaining_code, 1)
			else:
				remaining_code.remove_at(0)
				rec_load_modules(remaining_code, 0)
		
		elif bracket_level == 1:
			if remaining_code[0] == "":
				remaining_code.remove_at(0)
				rec_load_modules(remaining_code, 1)
			elif remaining_code[0] == "limit={":
				remaining_code.remove_at(0)
				while not remaining_code[0].contains("}"):
					remaining_code.remove_at(0)
				remaining_code.remove_at(0)
				rec_load_modules(remaining_code, 1)
			
			else:
				var module_name = remaining_code[0]
				var module_strings: PackedStringArray
				
				remaining_code.remove_at(0)
				bracket_level = 2
				
				while bracket_level > 1 and remaining_code.size() > 0:
					if remaining_code[0].contains("{"):
						bracket_level += 1
					if remaining_code[0].contains("}"):
						bracket_level -= 1
					module_strings.append(remaining_code[0])
					remaining_code.remove_at(0)
				print(module_strings)
				
				rec_load_modules(remaining_code, 1)

# Return an Array of all Lines in order without all comments, tabs and emptyspaces
func uncomment_lines(commented_string: String) -> PackedStringArray:
	var line_array = commented_string.split("\n")
	var line_uncommented_array: PackedStringArray
	
	for line in line_array:
		var line_uncommented = ""
		for character in line:
			if character == "#":
				break
			else:
				line_uncommented = line_uncommented + character
		
		for del in ["\t", "\r", " "]:
				line_uncommented = line_uncommented.replace(del, "")
		
		if line_uncommented != "":
			line_uncommented_array.append(line_uncommented)
	
	return line_uncommented_array
