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
				read_module(module_name, module_strings)
				
				rec_load_modules(remaining_code, 1)

func read_module(module_name: String, module_strings: PackedStringArray):
	var equipment = 0
	var category = ""
	var gui_category = ""
	var equipment_type = ""
	var gfx = ""
	var sfx = ""
	var stats = {}
	var stats_mult = {}
	var mission_stats = {}
	var mission_stats_mult = {}
	var mission_allowed = []
	var category_forbidden = []
	var category_allowed = {}
	var cost = 0
	
	# 0: Module 1: add_stats 2: multiply_stats 3: mission_type_stats 4: mission_type_stats/limit
	# 5: mission_type_stats/add_stats 6: mission_type_stats/multiply_stats
	var bracket_open = 0
	
	for line in module_strings:
		if bracket_open == 0:
			if line.contains("category=") and not line.contains("gui_category="):
				category = line.replace("category=", "")
			elif line.contains("gui_category="):
				gui_category = line.replace("gui_category=", "")
			elif line.contains("add_equipment_type="):
				equipment_type = line.replace("add_equipment_type=", "")
			elif line.contains("gfx="):
				gfx = line.replace("gfx=", "")
			elif line.contains("sfx="):
				sfx = line.replace("sfx=", "")
			elif line.contains("xp_cost="):
				cost = line.replace("xp_cost=", "")
				
			elif line.contains("add_stats={"):
				bracket_open = 1
				if line != "add_stats={":
					var temp_line = line.replace("add_stats={", "")
					if temp_line.contains("}"):
						bracket_open = 0
						temp_line = temp_line.replace("}", "")
					stats.merge(stat_handler(temp_line))
			
		elif bracket_open == 1:
			if line.contains("}"):
				bracket_open = 0
				if line != "}":
					var temp_line = line.replace("}", "")
					stats.merge(stat_handler(temp_line))
			else:
				stats.merge(stat_handler(line))
	
	print(stats)

func stat_handler(stat_string: String) -> Dictionary:
	var stat_array = stat_string.split("=")
	
	return {stat_array[0]: stat_array[1].to_float()}
