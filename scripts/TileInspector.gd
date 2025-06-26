# TileInspector.gd - Systém pro zobrazení detailů dlaždic a budov
extends Node2D

# Reference na ostatní systémy
@onready var building_system: Node2D = get_node("../BuildingSystem")
@onready var resource_manager: Node = get_node("/root/ResourceManager")
@onready var map_generator: Node2D = get_node("../")
@onready var tilemap: TileMap = get_node("../TileMap")
@onready var weather_system: Node2D = get_node("../WeatherSystem")

# UI prvky
var info_panel: PanelContainer
var info_label: RichTextLabel
var is_panel_visible = false

# Dragging functionality
var is_dragging = false
var drag_offset = Vector2.ZERO

# Highlight system
var highlight_elements: Array = []
var current_tile_pos: Vector2i

func _ready():
	print("TileInspector initialized")
	create_info_panel()
	set_process_input(true)
	
	# Připoj se k weather signálům pro real-time updates
	if weather_system:
		weather_system.weather_changed.connect(_on_weather_changed)

func _input(event):
	"""Zpracování input pro inspekci dlaždic"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Kontrola zda klik není do info panelu
			if is_panel_visible and is_click_in_panel(event.position):
				print("Click in info panel - ignoring")
				return
			
			# Jen pokud NENÍ building mode
			if building_system and not building_system.is_building_mode and not building_system.is_repair_mode:
				var mouse_pos = get_global_mouse_position()
				var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
				print("Inspecting tile: ", tile_pos)
				inspect_tile(tile_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			hide_inspection()

func inspect_tile(tile_pos: Vector2i):
	"""Inspektuje dlaždici"""
	current_tile_pos = tile_pos
	
	if not is_valid_tile_position(tile_pos):
		hide_inspection()
		return
	
	clear_highlight()
	
	# Vytvoř highlight
	if building_system.is_building_at_position(tile_pos):
		create_building_highlight(tile_pos)
		inspect_building(tile_pos)
	else:
		create_tile_highlight(tile_pos)
		inspect_terrain(tile_pos)
	
	show_info_panel()

func create_tile_highlight(tile_pos: Vector2i):
	"""Vytvoří statický highlight pro dlaždici"""
	var highlight = ColorRect.new()
	highlight.color = Color(0, 1, 1, 0.5)
	highlight.position = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	highlight.size = Vector2(64, 64)
	highlight.z_index = 50
	
	get_parent().add_child(highlight)
	highlight_elements.append(highlight)
	
	# Jednoduchá animace fade-in
	highlight.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(highlight, "modulate:a", 0.5, 0.3)

func create_building_highlight(tile_pos: Vector2i):
	"""Vytvoří highlight pro celou budovu"""
	var building_data = building_system.get_building_at_position(tile_pos)
	if building_data.is_empty():
		create_tile_highlight(tile_pos)
		return
	
	var building_type = building_data.get("type", -1)
	var building_def = building_system.building_definitions.get(building_type, {})
	var building_position = building_data.get("position", tile_pos)
	var building_size = building_def.get("size", Vector2i(1, 1))
	
	print("Highlighting building: ", building_def.get("name", "Unknown"))
	print("Position: ", building_position, " Size: ", building_size)
	
	# Pokud je budova 1x1, použij tile highlight
	if building_size.x == 1 and building_size.y == 1:
		create_tile_highlight(tile_pos)
		return
	
	# Hlavní highlight obdélník
	var main_highlight = ColorRect.new()
	main_highlight.color = Color(0, 1, 1, 0.3)
	main_highlight.position = Vector2(building_position.x * 64, building_position.y * 64)
	main_highlight.size = Vector2(building_size.x * 64, building_size.y * 64)
	main_highlight.z_index = 50
	
	get_parent().add_child(main_highlight)
	highlight_elements.append(main_highlight)
	
	# Outline obrys
	create_simple_outline(building_position, building_size)
	
	# Jednoduchá fade-in animace
	main_highlight.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(main_highlight, "modulate:a", 0.3, 0.3)

func create_simple_outline(building_pos: Vector2i, building_size: Vector2i):
	"""Vytvoří jednoduchý statický outline"""
	var outline_thickness = 3
	var outline_color = Color.CYAN
	
	var total_width = building_size.x * 64
	var total_height = building_size.y * 64
	var start_pos = Vector2(building_pos.x * 64, building_pos.y * 64)
	
	# 4 obdélníky pro outline
	var outlines = [
		# Horní
		{pos = start_pos - Vector2(outline_thickness, outline_thickness), 
		 size = Vector2(total_width + 2 * outline_thickness, outline_thickness)},
		# Dolní
		{pos = Vector2(start_pos.x - outline_thickness, start_pos.y + total_height), 
		 size = Vector2(total_width + 2 * outline_thickness, outline_thickness)},
		# Levý
		{pos = start_pos - Vector2(outline_thickness, outline_thickness), 
		 size = Vector2(outline_thickness, total_height + 2 * outline_thickness)},
		# Pravý
		{pos = Vector2(start_pos.x + total_width, start_pos.y - outline_thickness), 
		 size = Vector2(outline_thickness, total_height + 2 * outline_thickness)}
	]
	
	for outline_data in outlines:
		var outline = ColorRect.new()
		outline.color = outline_color
		outline.position = outline_data.pos
		outline.size = outline_data.size
		outline.z_index = 55
		
		get_parent().add_child(outline)
		highlight_elements.append(outline)
		
		# Fade-in animace
		outline.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(outline, "modulate:a", 0.8, 0.4)

func clear_highlight():
	"""Vyčistí všechny highlight elementy"""
	for element in highlight_elements:
		if element and is_instance_valid(element):
			element.queue_free()
	highlight_elements.clear()

func inspect_building(tile_pos: Vector2i):
	"""Inspektuje budovu"""
	var building_data = building_system.get_building_at_position(tile_pos)
	if building_data.is_empty():
		inspect_terrain(tile_pos)
		return
	
	var building_type = building_data.get("type", -1)
	var building_def = building_system.building_definitions.get(building_type, {})
	
	var info_text = generate_building_info(building_data, building_def)
	info_label.text = info_text

func inspect_terrain(tile_pos: Vector2i):
	"""Inspektuje terén"""
	var terrain_type = map_generator.terrain_grid[tile_pos.x][tile_pos.y]
	var info_text = generate_terrain_info(tile_pos, terrain_type)
	info_label.text = info_text

func generate_building_info(building_data: Dictionary, building_def: Dictionary) -> String:
	"""Generuje info o budově s repair informacemi"""
	var name = building_def.get("name", "Unknown Building")
	var position = building_data.get("position", Vector2i.ZERO)
	var building_type = building_data.get("type", -1)
	var damage = building_data.get("damage", 0.0)
	var durability = building_data.get("durability", 1.0)
	
	var text = "[center][color=cyan][font_size=16][b]%s[/b][/font_size][/color][/center]\n\n" % name
	text += "[color=yellow]Position:[/color] %s\n" % str(position)
	text += "[color=yellow]Size:[/color] %dx%d tiles\n" % [building_def.get("size", Vector2i(1,1)).x, building_def.get("size", Vector2i(1,1)).y]
	
	# Physical condition with repair info
	if damage > 0:
		var damage_color = "red" if damage > 0.5 else "orange"
		text += "[color=%s]Physical Damage:[/color] %.0f%%\n" % [damage_color, damage * 100]
		text += "[color=%s]Condition:[/color] %s\n" % [damage_color, building_system.get_condition_text(damage)]
		
		# Repair cost info
		if building_system.can_repair_building(Vector2i(position.x, position.y)):
			text += "[color=green]✓ Can be repaired[/color]\n"
			var repair_cost = building_def.get("repair_cost", {})
			if repair_cost.size() > 0:
				text += "[color=gray]Repair cost:[/color] "
				var cost_parts = []
				for resource_type in repair_cost:
					var resource_name = resource_manager.get_resource_name(resource_type)
					var cost = repair_cost[resource_type]
					cost_parts.append("%d %s" % [cost, resource_name])
				text += " • ".join(cost_parts) + "\n"
		else:
			text += "[color=red]✗ Cannot repair (insufficient resources)[/color]\n"
	else:
		text += "[color=green]Physical Condition:[/color] Excellent\n"
	
	# Durability rating
	var durability_color = "green"
	var durability_text = "Very High"
	if durability < 0.9:
		durability_color = "lime"
		durability_text = "High"
	if durability < 0.7:
		durability_color = "yellow"
		durability_text = "Medium"
	if durability < 0.5:
		durability_color = "orange"
		durability_text = "Low"
	
	text += "[color=%s]Durability:[/color] %s (%.0f%%)\n" % [durability_color, durability_text, durability * 100]
	
	# Efficiency
	var efficiency = building_system.get_building_efficiency(Vector2i(position.x, position.y))
	var efficiency_color = "green"
	if efficiency < 0.8:
		efficiency_color = "yellow"
	if efficiency < 0.5:
		efficiency_color = "orange"
	if efficiency < 0.3:
		efficiency_color = "red"
	
	text += "[color=%s]Operating Efficiency:[/color] %.0f%%\n" % [efficiency_color, efficiency * 100]
	
	# Weather effects
	if weather_system:
		var weather_status = weather_system.get_building_weather_status(building_type)
		var weather_color = weather_system.get_building_weather_status_color(building_type)
		text += "[color=%s]Weather Status:[/color] %s\n" % [weather_color, weather_status]
	
	# Production & Consumption with efficiency modifiers
	var production = building_def.get("production", {})
	if production.size() > 0:
		text += "\n[color=green][b]Production:[/b][/color]\n"
		for resource_type in production:
			var base_amount = production[resource_type]
			var effective_amount = base_amount * efficiency
			var resource_name = resource_manager.get_resource_name(resource_type)
			
			if efficiency < 1.0:
				text += "  [color=lime]▲[/color] %.1f %s/s [color=gray](%.1f base)[/color]\n" % [effective_amount, resource_name, base_amount]
			else:
				text += "  [color=lime]▲[/color] %.1f %s/s\n" % [base_amount, resource_name]
	
	var consumption = building_def.get("consumption", {})
	if consumption.size() > 0:
		text += "\n[color=orange][b]Consumption:[/b][/color]\n"
		for resource_type in consumption:
			var base_amount = consumption[resource_type]
			var effective_amount = base_amount * efficiency
			var resource_name = resource_manager.get_resource_name(resource_type)
			
			# Weather effects on consumption
			var weather_modified = false
			if weather_system and resource_name == "Energy":
				var weather_effects = weather_system.get_weather_effect_on_building(building_type)
				if "energy_consumption" in weather_effects:
					var modifier = weather_effects["energy_consumption"].get("modifier", 1.0)
					effective_amount *= modifier
					weather_modified = true
			
			if efficiency < 1.0 or weather_modified:
				var modifiers = []
				if efficiency < 1.0:
					modifiers.append("damage")
				if weather_modified:
					modifiers.append("weather")
				text += "  [color=red]▼[/color] %.1f %s/s [color=gray](%.1f base, +%s)[/color]\n" % [effective_amount, resource_name, base_amount, " + ".join(modifiers)]
			else:
				text += "  [color=red]▼[/color] %.1f %s/s\n" % [base_amount, resource_name]
	
	# Special building info
	if building_type == building_system.BuildingType.VESSEL:
		text += "\n[color=gold][b]🚀 ESCAPE VESSEL[/b][/color]\n"
		text += "[color=gold]This vessel will allow escape from Titan![/color]\n"
	
	# Placement restrictions info
	var restriction = building_def.get("placement_restriction", "any")
	if restriction != "any":
		text += "\n[color=yellow][b]Special Placement:[/b][/color]\n"
		match restriction:
			"near_methane":
				text += "[color=yellow]Must be near methane source[/color]\n"
			"near_mountains":
				text += "[color=yellow]Must be near ice mountains[/color]\n"
			"methane_sea_only":
				text += "[color=yellow]Must be built on methane sea[/color]\n"
	
	text += "\n[color=gray][i]Drag to move • Right-click to close[/i][/color]"
	return text

func generate_terrain_info(tile_pos: Vector2i, terrain_type: int) -> String:
	"""Generuje info o terénu"""
	var terrain_name = get_terrain_name(terrain_type)
	
	var text = "[center][color=orange][font_size=16][b]%s[/b][/font_size][/color][/center]\n\n" % terrain_name
	text += "[color=yellow]Position:[/color] %s\n" % str(tile_pos)
	text += "[color=yellow]Type:[/color] %s\n\n" % terrain_name
	
	if can_build_on_terrain(terrain_type):
		text += "[color=green]✓ Suitable for construction[/color]\n"
	else:
		text += "[color=red]✗ Cannot build here[/color]\n"
	
	# Description
	text += "\n[color=white][b]Description:[/b][/color]\n"
	text += "[color=lightgray]%s[/color]\n" % get_terrain_description(terrain_type)
	
	text += "\n[color=gray][i]Drag to move • Right-click to close[/i][/color]"
	return text

func get_terrain_name(terrain_type: int) -> String:
	if not map_generator:
		return "Unknown"
	
	match terrain_type:
		map_generator.TerrainType.NORMAL_SURFACE: return "Normal Surface"
		map_generator.TerrainType.METHANE_LAKE: return "Methane Lake"
		map_generator.TerrainType.METHANE_SEA: return "Methane Sea"
		map_generator.TerrainType.ICE_MOUNTAINS: return "Ice Mountains"
		_: return "Unknown Terrain"

func get_terrain_description(terrain_type: int) -> String:
	if not map_generator:
		return "Unknown terrain."
	
	match terrain_type:
		map_generator.TerrainType.NORMAL_SURFACE:
			return "Solid rocky ground typical of Titan's surface."
		map_generator.TerrainType.METHANE_LAKE:
			return "Liquid methane body. Rich in resources."
		map_generator.TerrainType.METHANE_SEA:
			return "Large methane sea. Impassable terrain."
		map_generator.TerrainType.ICE_MOUNTAINS:
			return "Elevated icy mountains. Good for drilling operations."
		_:
			return "Unknown terrain type."

func can_build_on_terrain(terrain_type: int) -> bool:
	if not map_generator:
		return false
	
	return terrain_type == map_generator.TerrainType.NORMAL_SURFACE or \
		   terrain_type == map_generator.TerrainType.ICE_MOUNTAINS

# UI Management functions
func create_info_panel():
	info_panel = PanelContainer.new()
	info_panel.position = Vector2(10, 300)
	info_panel.size = Vector2(350, 200)
	info_panel.visible = false
	info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	info_panel.z_index = 1000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(2)
	style.border_color = Color.CYAN
	info_panel.add_theme_stylebox_override("panel", style)
	
	# Hlavní VBox layout
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Header s close buttonem
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = "Tile Inspector"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color.CYAN)
	
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(hide_inspection)
	
	header.add_child(title_label)
	header.add_child(close_button)
	
	# ScrollContainer pro dlouhé texty
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Label
	info_label = RichTextLabel.new()
	info_label.fit_content = true
	info_label.bbcode_enabled = true
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	scroll.add_child(info_label)
	vbox.add_child(header)
	vbox.add_child(scroll)
	info_panel.add_child(vbox)
	
	# Přidej drag funkcionalitu
	info_panel.gui_input.connect(_on_panel_input)
	
	# Najdi UI root
	var ui_root = find_ui_root()
	if ui_root:
		ui_root.add_child(info_panel)
		print("Info panel added to UI root: ", ui_root.name)
	else:
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		canvas_layer.name = "TileInspectorUI"
		get_tree().current_scene.add_child(canvas_layer)
		canvas_layer.add_child(info_panel)
		print("Info panel added to new CanvasLayer")

func find_ui_root() -> Node:
	var current_scene = get_tree().current_scene
	
	for child in current_scene.get_children():
		if child is Control and (child.name.to_lower().contains("ui") or child.name.to_lower().contains("canvas")):
			return child
	
	for child in current_scene.get_children():
		if child is CanvasLayer:
			return child
	
	return null

func _on_panel_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		info_panel.position += event.position - drag_offset

func is_click_in_panel(click_pos: Vector2) -> bool:
	if not info_panel or not info_panel.visible:
		return false
	
	var panel_rect = Rect2(info_panel.global_position, info_panel.size)
	return panel_rect.has_point(click_pos)

func show_info_panel():
	info_panel.visible = true
	is_panel_visible = true
	
	# Fade-in animace
	info_panel.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(info_panel, "modulate", Color.WHITE, 0.2)

func hide_inspection():
	if not is_panel_visible:
		return
	
	print("Hiding inspection")
	
	# Fade-out animace
	var tween = create_tween()
	tween.tween_property(info_panel, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(func(): info_panel.visible = false)
	
	clear_highlight()
	is_panel_visible = false

func is_valid_tile_position(tile_pos: Vector2i) -> bool:
	return tile_pos.x >= 0 and tile_pos.y >= 0 and \
		   tile_pos.x < map_generator.MAP_WIDTH and \
		   tile_pos.y < map_generator.MAP_HEIGHT

# Weather event handlers
func _on_weather_changed(weather_type, severity):
	if is_panel_visible and building_system.is_building_at_position(current_tile_pos):
		inspect_building(current_tile_pos)
