extends Node

const AIR_CATEGORY_ARRAY: PackedStringArray = []
const NAVY_CATEGORY_ARRAY: PackedStringArray = []
const TANK_CATEGORY_ARRAY: PackedStringArray = []

var module_id_array = []
var module_dict = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for module_file in get_module_strings():
		rec_load_modules(uncomment_lines(module_file), 0)

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
				remaining_code[0] = remaining_code[0].replace("={", "")
				var module_name: String
				var module_strings: PackedStringArray
				
				if remaining_code[0] != "}":
					module_name = remaining_code[0]
				
				remaining_code.remove_at(0)
				bracket_level = 2
				
				while bracket_level > 1 and remaining_code.size() > 0:
					if remaining_code[0].contains("{"):
						bracket_level += 1
					if remaining_code[0].contains("}"):
						bracket_level -= 1
					module_strings.append(remaining_code[0])
					remaining_code.remove_at(0)
				
				if module_name != "":
					read_module(module_name, module_strings)
				
				rec_load_modules(remaining_code, 1)

func read_module(module_name: String, module_strings: PackedStringArray):
	var equipment = 0
	var category = ""
	var stats = {}
	var stats_mult = {}
	var mission_stats = {}
	var mission_stats_mult = {}
	var cost = 5
	
	# 0: Module 1: add_stats 2: multiply_stats 3: mission_type_stats 4: mission_type_stats/limit
	# 5: mission_type_stats/add_stats 6: mission_type_stats/multiply_stats
	var bracket_open = 0
	var mission_type_limit: PackedStringArray
	var mission_type_stat: Dictionary
	var mission_type_mult: Dictionary
	
	for line in module_strings:
		if bracket_open == 0:
			if line.contains("category=") and not line.contains("gui_category="):
				category = line.replace("category=", "")
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
			elif line.contains("multiply_stats={"):
				bracket_open = 2
				if line != "multiply_stats={":
					var temp_line = line.replace("multiply_stats={", "")
					if temp_line.contains("}"):
						bracket_open = 0
						temp_line = temp_line.replace("}", "")
					stats_mult.merge(stat_handler(temp_line))
			
			elif line.contains("mission_type_stats={"):
				mission_type_limit.clear()
				mission_type_stat.clear()
				
				bracket_open = 3
				if line != "mission_type_stats={":
					var temp_line = line.replace("mission_type_stats={", "")
					
					if temp_line.contains("limit={"):
						temp_line = temp_line.replace("limit={", "")
						if temp_line.contains("}"):
							temp_line = temp_line.replace("}", "")
							if temp_line != "":
								mission_type_limit.append(temp_line)
						else:
							bracket_open = 4
							if temp_line != "":
								mission_type_limit.append(temp_line)
					
					if temp_line.contains("}"):
						bracket_open = 0
						temp_line = temp_line.replace("}", "")
						
						for mission_type in mission_type_limit:
							if mission_type_stat != {}:
								mission_stats.merge({mission_type: mission_type_stat})
							if mission_type_mult != {}:
								mission_stats_mult.merge({mission_type: mission_type_mult})
					
					if temp_line.contains("add_stats={"):
						temp_line = temp_line.replace("add_stats={", "")
			
		elif bracket_open == 1:
			if line.contains("}"):
				bracket_open = 0
				if line != "}":
					var temp_line = line.replace("}", "")
					stats.merge(stat_handler(temp_line))
			elif line.contains("="):
				stats.merge(stat_handler(line))
		
		elif bracket_open == 2:
			if line.contains("}"):
				bracket_open = 0
				if line != "}":
					var temp_line = line.replace("}", "")
					stats_mult.merge(stat_handler(temp_line))
			elif line.contains("="):
				stats_mult.merge(stat_handler(line))
		
		elif bracket_open == 3:
			var temp_line = line
			
			if temp_line.contains("limit={"):
				temp_line = temp_line.replace("limit={", "")
				if temp_line.contains("}"):
					temp_line = temp_line.replace("}", "")
					if temp_line != "":
						mission_type_limit.append(temp_line)
				else:
					bracket_open = 4
					if temp_line != "":
						mission_type_limit.append(temp_line)
			
			if temp_line.contains("}"):
				bracket_open = 0
				temp_line = temp_line.replace("}", "")
				
				for mission_type in mission_type_limit:
					if mission_type_stat != {}:
						mission_stats.merge({mission_type: mission_type_stat})
					if mission_type_mult != {}:
						mission_stats_mult.merge({mission_type: mission_type_mult})
			
			if temp_line.contains("add_stats={"):
				temp_line = temp_line.replace("add_stats={", "")
				if temp_line.contains("}"):
					temp_line = temp_line.replace("}", "")
				else:
					bracket_open = 5
				
				if temp_line.contains("="):
					for expression in temp_line.split(" "):
						mission_type_stat.merge(stat_handler(temp_line))
			
			if temp_line.contains("multiply_stats={"):
				temp_line = temp_line.replace("multiply_stats={", "")
				if temp_line.contains("}"):
					temp_line = temp_line.replace("}", "")
				else:
					bracket_open = 6
				
				if temp_line.contains("="):
					for expression in temp_line.split(" "):
						mission_type_mult.merge(stat_handler(temp_line))
		
		elif bracket_open == 4:
			var temp_line = line
			
			if temp_line.contains("}"):
				bracket_open = 3
				temp_line = temp_line.replace("}", "")
				if temp_line != "":
					for expression in temp_line.split(" "):
						mission_type_limit.append(expression)

			if temp_line != "":
				for expression in temp_line.split(" "):
					mission_type_limit.append(expression)
		
		elif bracket_open == 5:
			var temp_line = line
			
			if temp_line.contains("}"):
				bracket_open = 3
				temp_line = temp_line.replace("}", "")
				if temp_line.contains("="):
					for expression in temp_line.split("="):
						mission_type_stat.merge(stat_handler(temp_line))
			elif temp_line.contains("="):
				for expression in temp_line.split("="):
					mission_type_stat.merge(stat_handler(temp_line))
		
		elif bracket_open == 6:
			var temp_line = line
			
			if temp_line.contains("}"):
				bracket_open = 3
				temp_line = temp_line.replace("}", "")
				if temp_line.contains("="):
					for expression in temp_line.split("="):
						mission_type_mult.merge(stat_handler(temp_line))
			elif temp_line.contains("="):
				for expression in temp_line.split("="):
					mission_type_mult.merge(stat_handler(temp_line))
	
	var module_array = [category, stats, stats_mult, mission_stats, mission_stats_mult, cost]
	module_dict.merge({module_name: module_array})
	module_id_array.append(module_name)

func stat_handler(stat_string: String) -> Dictionary:
	var stat_array = stat_string.split("=")
	
	return {stat_array[0]: stat_array[1].to_float()}

func equipment_cat_handler(category: String) -> int:
	if category in AIR_CATEGORY_ARRAY:
		return 1
	elif category in NAVY_CATEGORY_ARRAY:
		return 2
	elif category in TANK_CATEGORY_ARRAY:
		return 3
	else:
		return 0
