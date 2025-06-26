# === TITAN QUEST - ENHANCED BUILDING UI ===
# BuildingUI.gd - UI pro výběr budov s variantami a repair módem

extends Control

@onready var building_system: Node2D = get_node("../../BuildingSystem")
@onready var resource_manager: Node = get_node("/root/ResourceManager")

# UI elements
var building_container: VBoxContainer
var repair_button: Button
var repair_status_label: Label

func _ready():
	print("=== Enhanced BuildingUI initialized ===")
	
	# Počkej na inicializaci building_system
	await get_tree().process_frame
	
	if not building_system:
		print("ERROR: BuildingSystem not found!")
		building_system = get_node("../../BuildingSystem")
	
	create_enhanced_building_ui()
	
	# Připoj signály
	if building_system:
		building_system.building_repaired.connect(_on_building_repaired)
		building_system.victory_condition_met.connect(_on_victory)
	
	# Pozice UI
	position = Vector2(get_viewport().size.x - 380, 50)

func create_enhanced_building_ui():
	"""Vytvoří vylepšené UI pro budovy"""
	# Hlavní kontejner
	var main_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(2)
	style.border_color = Color.CYAN
	main_panel.add_theme_stylebox_override("panel", style)
	
	building_container = VBoxContainer.new()
	building_container.add_theme_constant_override("separation", 5)
	
	# Header
	var header = Label.new()
	header.text = "BUILDING MENU"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color.CYAN)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	building_container.add_child(header)
	
	# Separator
	var separator1 = HSeparator.new()
	building_container.add_child(separator1)
	
	# Repair button
	repair_button = Button.new()
	repair_button.text = "🔧 REPAIR MODE"
	repair_button.custom_minimum_size = Vector2(340, 30)
	repair_button.pressed.connect(_on_repair_mode_pressed)
	building_container.add_child(repair_button)
	
	# Repair status
	repair_status_label = Label.new()
	repair_status_label.text = "No buildings need repair"
	repair_status_label.add_theme_font_size_override("font_size", 10)
	repair_status_label.add_theme_color_override("font_color", Color.GRAY)
	building_container.add_child(repair_status_label)
	
	var separator2 = HSeparator.new()
	building_container.add_child(separator2)
	
	# Building categories
	create_building_categories()
	
	main_panel.add_child(building_container)
	add_child(main_panel)

func create_building_categories():
	"""Vytvoří kategorie budov s variantami"""
	
	# HABITAT (jedinečná budova)
	create_category_header("🏠 HABITAT")
	create_single_building_button(building_system.BuildingType.HABITAT)
	
	# POWER GENERATORS
	create_category_header("⚡ POWER GENERATORS")
	create_building_variant_buttons("POWER_GENERATOR", [
		building_system.BuildingType.POWER_GENERATOR_BASIC,
		building_system.BuildingType.POWER_GENERATOR_ADVANCED
	])
	
	# FARMS
	create_category_header("🌱 FARMS")
	create_building_variant_buttons("FARM", [
		building_system.BuildingType.FARM_BASIC,
		building_system.BuildingType.FARM_ADVANCED
	])
	
	# WATER EXTRACTORS
	create_category_header("💧 WATER EXTRACTORS")
	create_building_variant_buttons("WATER_EXTRACTOR", [
		building_system.BuildingType.WATER_EXTRACTOR_BASIC,
		building_system.BuildingType.WATER_EXTRACTOR_ADVANCED
	])
	
	# METHANE PROCESSORS
	create_category_header("🔥 METHANE PROCESSORS")
	var methane_note = Label.new()
	methane_note.text = "   (Must be near methane lake/sea)"
	methane_note.add_theme_font_size_override("font_size", 9)
	methane_note.add_theme_color_override("font_color", Color.YELLOW)
	building_container.add_child(methane_note)
	
	create_building_variant_buttons("METHANE_PROCESSOR", [
		building_system.BuildingType.METHANE_PROCESSOR_BASIC,
		building_system.BuildingType.METHANE_PROCESSOR_ADVANCED
	])
	
	# DRILLING TOWERS
	create_category_header("⚒️ DRILLING TOWERS")
	var drilling_note = Label.new()
	drilling_note.text = "   (Must be near ice mountains)"
	drilling_note.add_theme_font_size_override("font_size", 9)
	drilling_note.add_theme_color_override("font_color", Color.YELLOW)
	building_container.add_child(drilling_note)
	
	create_building_variant_buttons("DRILLING_TOWER", [
		building_system.BuildingType.DRILLING_TOWER_BASIC,
		building_system.BuildingType.DRILLING_TOWER_ADVANCED
	])
	
	# ESCAPE VESSEL
	create_category_header("🚀 ESCAPE VESSEL")
	var vessel_note = Label.new()
	vessel_note.text = "   (Must be built on methane sea - VICTORY!)"
	vessel_note.add_theme_font_size_override("font_size", 9)
	vessel_note.add_theme_color_override("font_color", Color.GOLD)
	building_container.add_child(vessel_note)
	
	create_single_building_button(building_system.BuildingType.VESSEL)

func create_category_header(text: String):
	"""Vytvoří header pro kategorii budov"""
	var separator = HSeparator.new()
	building_container.add_child(separator)
	
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	building_container.add_child(header)

func create_single_building_button(building_type):
	"""Vytvoří tlačítko pro jedinou budovu"""
	var building_def = building_system.building_definitions[building_type]
	var button = create_enhanced_building_button(building_type, building_def, false)
	building_container.add_child(button)

func create_building_variant_buttons(category: String, building_types: Array):
	"""Vytvoří tlačítka pro varianty budovy"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	
	for i in range(building_types.size()):
		var building_type = building_types[i]
		var building_def = building_system.building_definitions[building_type]
		var is_advanced = i > 0  # První je basic, zbytek advanced
		
		var button = create_enhanced_building_button(building_type, building_def, is_advanced)
		button.custom_minimum_size = Vector2(165, 50)  # Menší pro varianty
		hbox.add_child(button)
	
	building_container.add_child(hbox)

func create_enhanced_building_button(building_type, building_def: Dictionary, is_advanced: bool) -> Button:
	"""Vytvoří vylepšené tlačítko pro budovu"""
	var button = Button.new()
	
	# Text tlačítka
	var button_text = building_def["name"]
	if is_advanced:
		button_text += "\n(ADVANCED)"
	
	button.text = button_text
	button.custom_minimum_size = Vector2(340, 50)
	
	# Styling podle typu
	if is_advanced:
		button.add_theme_color_override("font_color", Color.GOLD)
	elif building_type == building_system.BuildingType.VESSEL:
		button.add_theme_color_override("font_color", Color.CYAN)
	elif building_type == building_system.BuildingType.HABITAT:
		button.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	
	# Tooltip s detailními informacemi
	var tooltip = create_detailed_tooltip(building_def, is_advanced)
	button.tooltip_text = tooltip
	
	# Callback
	button.pressed.connect(func(): _on_building_selected(building_type))
	
	return button

func create_detailed_tooltip(building_def: Dictionary, is_advanced: bool) -> String:
	"""Vytvoří detailní tooltip pro budovu"""
	var tooltip = "[b]%s[/b]\n" % building_def["name"]
	
	if is_advanced:
		tooltip += "[color=gold]ADVANCED VARIANT[/color]\n"
	
	tooltip += "Size: %dx%d\n\n" % [building_def["size"].x, building_def["size"].y]
	
	# Costs
	tooltip += "[color=yellow]COST:[/color]\n"
	for resource_type in building_def["cost"]:
		var resource_name = resource_manager.get_resource_name(resource_type)
		var cost = building_def["cost"][resource_type]
		var available = resource_manager.get_resource_amount(resource_type)
		var color = "red" if available < cost else "white"
		tooltip += "[color=%s]  %s: %d (have: %.0f)[/color]\n" % [color, resource_name, cost, available]
	
	# Production
	if building_def["production"].size() > 0:
		tooltip += "\n[color=green]PRODUCTION:[/color]\n"
		for resource_type in building_def["production"]:
			var resource_name = resource_manager.get_resource_name(resource_type)
			var amount = building_def["production"][resource_type]
			tooltip += "[color=lime]  +%.1f %s/s[/color]\n" % [amount, resource_name]
	
	# Consumption
	if building_def["consumption"].size() > 0:
		tooltip += "\n[color=orange]CONSUMPTION:[/color]\n"
		for resource_type in building_def["consumption"]:
			var resource_name = resource_manager.get_resource_name(resource_type)
			var amount = building_def["consumption"][resource_type]
			tooltip += "[color=red]  -%.1f %s/s[/color]\n" % [amount, resource_name]
	
	# Durability
	var durability = building_def.get("durability", 1.0)
	var durability_text = ""
	if durability >= 0.9:
		durability_text = "[color=green]Very High[/color]"
	elif durability >= 0.7:
		durability_text = "[color=lime]High[/color]"
	elif durability >= 0.5:
		durability_text = "[color=yellow]Medium[/color]"
	else:
		durability_text = "[color=orange]Low[/color]"
	
	tooltip += "\n[color=gray]Durability: %s[/color]" % durability_text
	
	# Placement restrictions
	var restriction = building_def.get("placement_restriction", "any")
	if restriction != "any":
		tooltip += "\n[color=yellow]Special Placement Required[/color]"
	
	return tooltip

func _on_building_selected(building_type):
	"""Callback pro výběr budovy"""
	print("Selected building: ", building_system.building_definitions[building_type]["name"])
	building_system.enter_building_mode(building_type)

func _on_repair_mode_pressed():
	"""Callback pro repair mode"""
	building_system.enter_repair_mode()
	update_repair_status()

func _on_building_repaired(building_type, position):
	"""Callback při opravě budovy"""
	print("Building repaired: ", building_system.building_definitions[building_type]["name"])
	update_repair_status()

func _on_victory():
	"""Callback při vítězství"""
	print("🎉 VICTORY ACHIEVED! 🎉")
	# Zde můžete přidat victory screen nebo jiné efekty

func update_repair_status():
	"""Aktualizuje status repair módu"""
	if not building_system:
		return
	
	var damaged_buildings = building_system.get_buildings_needing_repair()
	
	if damaged_buildings.size() == 0:
		repair_status_label.text = "No buildings need repair"
		repair_status_label.add_theme_color_override("font_color", Color.GRAY)
		repair_button.text = "🔧 REPAIR MODE"
	else:
		repair_status_label.text = "%d buildings need repair" % damaged_buildings.size()
		repair_status_label.add_theme_color_override("font_color", Color.ORANGE)
		repair_button.text = "🔧 REPAIR MODE (%d)" % damaged_buildings.size()

func _process(_delta):
	"""Pravidelná aktualizace UI"""
	# Aktualizuj repair status každou sekundu
	if Engine.get_process_frames() % 60 == 0:  # 60 FPS = 1 sekunda
		update_repair_status()

# Debug functions
func debug_print_ui_status():
	"""Debug informace o UI"""
	print("=== BUILDING UI STATUS ===")
	print("Building system connected: ", building_system != null)
	print("Resource manager connected: ", resource_manager != null)
	print("UI position: ", position)
	print("UI visible: ", visible)
