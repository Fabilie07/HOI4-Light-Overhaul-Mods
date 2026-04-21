extends Node

# Placeholder
var game_path = "D:/Spiele/SteamLibrary/steamapps/common/Hearts of Iron IV"

var tech_id_array: PackedStringArray
var tech_dict: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for technology in get_tech_strings():
		get_technology_array(uncomment_lines(technology))
	
	print(tech_id_array)

# Return a PackedStringArray containing each .txt file in common/technologies as a String
func get_tech_strings() -> PackedStringArray:
	var tech_string_array: PackedStringArray
	
	for tech_file_str in DirAccess.get_files_at(game_path+"/common/technologies"):
		if tech_file_str.get_extension() == "txt":
			var tech_file = FileAccess.open(game_path+"/common/technologies/"+tech_file_str, FileAccess.READ)
			var tech_script = tech_file.get_as_text()
			tech_string_array.append(tech_script)
	
	return tech_string_array

# Remove all Comments and Indents
func uncomment_lines(technology: String) -> PackedStringArray:
	var line_array = technology.split("\n")
	var uncommented_array: PackedStringArray
	
	for line in line_array:
		var line_uncommented = ""
		for character in line:
			if character in ["#", "@"]:
				break
			else:
				line_uncommented = line_uncommented + character
		
		for del in ["\t", "\r"]:
			line_uncommented = line_uncommented.replace(del, "")
		
		uncommented_array.append(line_uncommented)
	
	return uncommented_array

func get_technology_array(line_array: PackedStringArray):
	var bracket_level = 0
	var tech_name: String
	var tech_line_array: PackedStringArray
	
	for line in line_array:
		if bracket_level == 0:
			line = line.replace(" ", "")
			if line.contains("technologies={"):
				bracket_level = 1
		
		elif bracket_level == 1:
			line = line.replace(" ", "")
			if line.contains("}"):
				bracket_level = 0
			elif line.contains("={"):
				tech_name = line.replace("={", "")
				tech_id_array.append(tech_name)
				bracket_level = 2
		
		elif bracket_level > 1:
			tech_line_array.append(line)
			
			if line.contains("{"):
				bracket_level += 1
			if line.contains("}"):
				bracket_level -= 1
			
			if bracket_level == 1:
				tech_line_array[-1] = ""
				technology_handler(tech_name, tech_line_array)
				tech_line_array = []
				bracket_level = 1

# If the Technology unlocks Modules, save it to tech_dict
func technology_handler(tech_name: String, line_array: PackedStringArray):
	pass
