extends ItemList

var module_id_array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_modules()

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
			print(module_id_array)
