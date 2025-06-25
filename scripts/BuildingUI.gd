# === TITAN QUEST - DAY 2 ===
# BuildingUI.gd - UI pro výběr budov
# OPRAVENÁ VERZE - správné reference na enum

extends Control

@onready var building_system: Node2D = get_node("../../BuildingSystem")

func _ready():
	print("=== BuildingUI DEBUG ===")
	print("BuildingUI initialized")
	print("BuildingUI position: ", position)
	print("BuildingUI size: ", size)
	print("BuildingUI visible: ", visible)
	
	# Počkej až se building_system inicializuje
	await get_tree().process_frame
	
	# Debug building system reference
	if building_system:
		print("BuildingSystem found: ", building_system.name)
	else:
		print("ERROR: BuildingSystem not found!")
		# Zkus najít building system jinak
		var main_node = get_tree().get_first_node_in_group("main")
		if not main_node:
			main_node = get_node("../../")
		building_system = main_node.get_node("BuildingSystem")
		print("Alternative search result: ", building_system)
	
	create_building_buttons()
	
	# Pozice ABSOLUTNÍ místo relative
	position = Vector2(get_viewport().size.x - 320, get_viewport().size.y - 200)
	print("Final position: ", position)

func create_building_buttons():
	"""Vytvoří tlačítka pro všechny budovy"""
	if not building_system:
		print("BuildingSystem not found!")
		return
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Použijeme čísla místo enum (0, 1, 2, 3, 4)
	for building_type in range(5):  # 5 typů budov
		var button = create_building_button(building_type)
		vbox.add_child(button)

func create_building_button(building_type: int) -> Button:
	"""Vytvoří tlačítko pro jednu budovu"""
	var building_def = building_system.building_definitions[building_type]
	
	var button = Button.new()
	button.text = building_def["name"]
	button.custom_minimum_size = Vector2(280, 30)
	
	# Tooltip s informacemi
	var tooltip = "Cost: "
	for resource_type in building_def["cost"]:
		var resource_manager = get_node("/root/ResourceManager")
		var resource_name = resource_manager.get_resource_name(resource_type)
		tooltip += "%s: %d " % [resource_name, building_def["cost"][resource_type]]
	button.tooltip_text = tooltip
	
	# Připoj callback
	button.pressed.connect(func(): building_system.enter_building_mode(building_type))
	
	return button
