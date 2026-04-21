extends ItemList

@onready var module_loader = $"../ModuleLoader"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for module in module_loader.module_id_array:
		add_item(module)
