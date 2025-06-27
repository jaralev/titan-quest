# === TITAN QUEST - GAME MANAGER ===
# GameManager.gd - Správa herních stavů, vítězství a repair systému

extends Node

# Game state
enum GameState {
	PLAYING,
	PAUSED,
	VICTORY,
	GAME_OVER
}

var current_state = GameState.PLAYING
var game_time = 0.0
var victory_achieved = false

# References
var building_system: Node2D
var resource_manager: Node
var weather_system: Node2D

# UI references
var victory_screen: Control
var repair_notifications: Control

# Statistics
var buildings_built = 0
var buildings_repaired = 0
var disasters_survived = 0

signal game_state_changed(new_state: GameState)
signal victory_achieved_signal()

func _ready():
	print("GameManager initialized")
	
	# Find references
	await get_tree().process_frame
	building_system = get_tree().get_first_node_in_group("building_system")
	if not building_system:
		building_system = get_node_or_null("/root/Main/BuildingSystem")
	
	resource_manager = get_node("/root/ResourceManager")
	weather_system = get_tree().get_first_node_in_group("weather_system")
	if not weather_system:
		weather_system = get_node_or_null("/root/Main/WeatherSystem")
	
	# Connect signals
	if building_system:
		building_system.victory_condition_met.connect(_on_victory_condition_met)
		building_system.building_repaired.connect(_on_building_repaired)
		print("Connected to BuildingSystem")
	
	if weather_system:
		weather_system.weather_changed.connect(_on_weather_changed)
		print("Connected to WeatherSystem")
	
	create_ui_elements()

func _process(delta):
	if current_state == GameState.PLAYING:
		game_time += delta

# CENTRALIZED INPUT HANDLING
func _unhandled_input(event):
	"""Globální input handling - zpracovává všechny herní klávesy"""
	# Pouze zpracovávej input když hra běží nebo je pausnutá
	if current_state == GameState.VICTORY:
		return  # Victory screen má vlastní input handling
	
	# Reset celé hry pomocí SPACE
	if event.is_action_pressed("ui_accept"):  # SPACE nebo ENTER
		print("=== REGENERATING GAME VIA GAMEMANAGER ===")
		reset_game_state()
	
	# Debug statistiky pomocí ESC
	if event.is_action_pressed("ui_cancel"):  # ESC
		debug_show_stats()
		
		# Také zobrazit terrain statistiky
		var map_generator = get_tree().get_first_node_in_group("map_generator")
		if not map_generator:
			map_generator = get_node_or_null("/root/Main")
		if map_generator and map_generator.has_method("count_terrain_types"):
			map_generator.count_terrain_types()
	
	# Debug weather pomocí TAB
	if event.is_action_pressed("ui_select"):  # TAB
		if weather_system and weather_system.has_method("trigger_random_disaster"):
			weather_system.trigger_random_disaster()
			print("Debug: Triggered random disaster via GameManager")

# CENTRALIZED RESET SYSTEM
func reset_game_state():
	"""Centralizovaný reset celé hry - volá se z jakéhokoliv místa"""
	print("=== RESETTING GAME ===")
	
	# Spusť fade efekt
	await start_reset_fade()
	
	# 1. Reset game manager statistics a stavu
	reset_statistics()
	
	# 2. Reset resource manager
	if resource_manager and resource_manager.has_method("reset_to_initial_state"):
		resource_manager.reset_to_initial_state()
	
	# 3. Reset building system (včetně building/repair módu)
	var building_sys = building_system
	if not building_sys:
		building_sys = get_tree().get_first_node_in_group("building_system")
	if not building_sys:
		building_sys = get_node_or_null("/root/Main/BuildingSystem")
	if not building_sys:
		var main_node = get_tree().current_scene
		if main_node:
			for child in main_node.get_children():
				if child.name == "BuildingSystem" or child.get_script() != null:
					if child.has_method("reset_buildings"):
						building_sys = child
						break
	
	if building_sys and building_sys.has_method("reset_buildings"):
		if building_sys.has_method("force_exit_all_modes"):
			building_sys.force_exit_all_modes()
		
		await building_sys.reset_buildings()
		
		# Force reset módů
		if "is_building_mode" in building_sys:
			building_sys.is_building_mode = false
		if "is_repair_mode" in building_sys:
			building_sys.is_repair_mode = false
		
		if building_sys.has_method("clear_building_preview"):
			building_sys.clear_building_preview()
	
	# 4. Reset weather system
	var weather_sys = weather_system
	if not weather_sys:
		weather_sys = get_tree().get_first_node_in_group("weather_system")
	if not weather_sys:
		weather_sys = get_node_or_null("/root/Main/WeatherSystem")
	
	if weather_sys:
		if weather_sys.has_method("change_weather"):
			weather_sys.change_weather(0)  # CLEAR = 0
	
	# 5. Reset map generator a regeneruj mapu
	var map_gen = get_tree().current_scene
	if map_gen and map_gen.has_method("generate_map") and map_gen.has_method("render_map"):
		map_gen.generate_map()
		map_gen.render_map()
	
	# 6. Reset tile inspector
	var tile_inspector = get_tree().get_first_node_in_group("tile_inspector")
	if not tile_inspector:
		tile_inspector = get_node_or_null("/root/Main/TileInspector")
	
	if tile_inspector and tile_inspector.has_method("hide_inspection"):
		tile_inspector.hide_inspection()
	
	# 7. Reset UI elements včetně BuildingUI
	reset_ui_elements()
	
	var building_ui = get_tree().get_first_node_in_group("building_ui")
	if not building_ui:
		building_ui = get_node_or_null("/root/Main/BuildingUI")
	if not building_ui:
		var scene = get_tree().current_scene
		if scene:
			for child in scene.get_children():
				if child.name == "BuildingUI" or child.name.contains("UI"):
					building_ui = child
					break
	
	if building_ui:
		if building_ui.has_method("reset_ui"):
			building_ui.reset_ui()
		elif building_ui.has_method("deselect_all"):
			building_ui.deselect_all()
		elif building_ui.has_method("clear_selection"):
			building_ui.clear_selection()
	
	# Dokončí fade efekt
	await complete_reset_fade()
	
	print("=== GAME RESET COMPLETE ===")

# FADE EFFECT SYSTEM
var fade_overlay: ColorRect = null

func start_reset_fade() -> void:
	"""Spustí fade to black efekt"""
	if not fade_overlay:
		create_fade_overlay()
	
	fade_overlay.visible = true
	fade_overlay.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate", Color.BLACK, 0.3)
	await tween.finished

func complete_reset_fade() -> void:
	"""Dokončí fade from black efekt"""
	if not fade_overlay:
		return
	
	# Krátké čekání aby se reset dokončil
	await get_tree().create_timer(0.2).timeout
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate", Color.TRANSPARENT, 0.4)
	await tween.finished
	
	fade_overlay.visible = false

func create_fade_overlay():
	"""Vytvoří fade overlay"""
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color.BLACK
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false
	
	# Přidej na nejvyšší úroveň
	get_tree().current_scene.add_child(fade_overlay)
	
	# Zajisti že je na vrchu
	fade_overlay.z_index = 1000

func reset_ui_elements():
	"""Reset všech UI elementů"""
	# Skryj victory screen
	if victory_screen and victory_screen.visible:
		victory_screen.visible = false
		print("✅ Victory screen hidden")
	
	# Vyčisti repair notifications
	if repair_notifications:
		for child in repair_notifications.get_children():
			child.queue_free()
		print("✅ Repair notifications cleared")

func reset_statistics():
	"""Resetuje herní statistiky a stav"""
	game_time = 0.0
	buildings_built = 0
	buildings_repaired = 0
	disasters_survived = 0
	victory_achieved = false
	current_state = GameState.PLAYING
	
	print("✅ Game statistics and state reset")

func create_ui_elements():
	"""Vytvoří UI elementy pro game management"""
	# Victory screen
	create_victory_screen()
	
	# Repair notifications
	create_repair_notifications()

func create_victory_screen():
	"""Vytvoří victory screen"""
	victory_screen = Control.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.visible = false
	victory_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fullscreen background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	victory_screen.add_child(bg)
	
	# Victory panel
	var panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.custom_minimum_size = Vector2(600, 400)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.3, 0.1, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.set_border_width_all(3)
	style.border_color = Color.GOLD
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	
	# Victory title
	var title = Label.new()
	title.text = "🎉 VICTORY! 🎉"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Victory message
	var message = Label.new()
	message.text = "Congratulations! You have successfully built the Escape Vessel!\nYour colony can now leave Titan and return to Earth!"
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color.WHITE)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message)
	
	# Statistics
	var stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var play_again_btn = Button.new()
	play_again_btn.text = "Play Again"
	play_again_btn.custom_minimum_size = Vector2(120, 40)
	play_again_btn.pressed.connect(_on_play_again_pressed)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit Game"
	quit_btn.custom_minimum_size = Vector2(120, 40)
	quit_btn.pressed.connect(_on_quit_game_pressed)
	
	button_hbox.add_child(play_again_btn)
	button_hbox.add_child(quit_btn)
	vbox.add_child(button_hbox)
	
	panel.add_child(vbox)
	victory_screen.add_child(panel)
	
	# Add to scene tree
	get_tree().current_scene.add_child(victory_screen)

func create_repair_notifications():
	"""Vytvoří systém notifikací pro opravy"""
	repair_notifications = Control.new()
	repair_notifications.name = "RepairNotifications"
	repair_notifications.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position in top-right corner
	repair_notifications.anchors_preset = Control.PRESET_TOP_RIGHT
	repair_notifications.position = Vector2(-300, 100)
	
	get_tree().current_scene.add_child(repair_notifications)

func _on_victory_condition_met():
	"""Callback při splnění vítězné podmínky"""
	print("🎉 VICTORY CONDITION MET! 🎉")
	victory_achieved = true
	current_state = GameState.VICTORY
	
	# Update statistics
	update_victory_statistics()
	
	# Show victory screen
	show_victory_screen()
	
	# Emit signal
	victory_achieved_signal.emit()
	game_state_changed.emit(GameState.VICTORY)

func show_victory_screen():
	"""Zobrazí victory screen"""
	if victory_screen:
		victory_screen.visible = true
		
		# Update statistics display
		var stats_label = victory_screen.get_node("PanelContainer/VBoxContainer/StatsLabel")
		if stats_label:
			var stats_text = "Game Statistics:\n"
			stats_text += "Time played: %s\n" % format_time(game_time)
			stats_text += "Buildings built: %d\n" % buildings_built
			stats_text += "Buildings repaired: %d\n" % buildings_repaired
			stats_text += "Disasters survived: %d" % disasters_survived
			stats_label.text = stats_text

func update_victory_statistics():
	"""Aktualizuje statistiky pro victory screen"""
	if building_system:
		buildings_built = building_system.get_all_buildings().size()

func _on_building_repaired(building_type, position):
	"""Callback při opravě budovy"""
	buildings_repaired += 1
	show_repair_notification(building_type, position)

func _on_weather_changed(weather_type, severity):
	"""Callback při změně počasí"""
	if weather_type != 0:  # Not CLEAR
		disasters_survived += 1

func show_repair_notification(building_type, position):
	"""Zobrazí notifikaci o opravě"""
	if not repair_notifications:
		return
	
	var building_name = "Unknown"
	if building_system and building_type in building_system.building_definitions:
		building_name = building_system.building_definitions[building_type]["name"]
	
	var notification = create_notification("🔧 Building Repaired", 
		"%s at %s has been repaired" % [building_name, str(position)])
	
	repair_notifications.add_child(notification)
	
	# Auto-remove after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(
		func(): 
			if notification and is_instance_valid(notification):
				notification.queue_free()
	)

func create_notification(title: String, message: String) -> Control:
	"""Vytvoří notifikační panel"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.2, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(1)
	style.border_color = Color.GREEN
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 10)
	message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	vbox.add_child(title_label)
	vbox.add_child(message_label)
	panel.add_child(vbox)
	
	# Fade in animation
	panel.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
	
	return panel

func _on_play_again_pressed():
	"""Restart hry - používá centralizovaný reset"""
	print("Restarting game via GameManager...")
	reset_game_state()

func _on_quit_game_pressed():
	"""Ukončení hry"""
	print("Quitting game...")
	get_tree().quit()

func format_time(seconds: float) -> String:
	"""Formátuje čas do čitelné podoby"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

# Public API
func get_game_time() -> float:
	return game_time

func get_current_state() -> GameState:
	return current_state

func is_victory_achieved() -> bool:
	return victory_achieved

func get_statistics() -> Dictionary:
	return {
		"game_time": game_time,
		"buildings_built": buildings_built,
		"buildings_repaired": buildings_repaired,
		"disasters_survived": disasters_survived
	}

# Convenience funkce pro jiné skripty
func trigger_game_reset():
	"""Veřejná funkce pro spuštění resetu z jiných skriptů"""
	reset_game_state()

# Debug functions
func debug_trigger_victory():
	"""Debug funkce pro spuštění vítězství"""
	_on_victory_condition_met()

func debug_print_scene_tree():
	"""Debug funkce pro výpis scene tree"""
	print("=== SCENE TREE DEBUG ===")
	var main_node = get_tree().current_scene
	print("Current scene: ", main_node.name if main_node else "None")
	print("Current scene path: ", main_node.get_path() if main_node else "None")
	print("Current scene script: ", str(main_node.get_script()) if main_node and main_node.get_script() else "None")
	
	if main_node:
		print("Main node children:")
		for child in main_node.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
			print("    Path: ", child.get_path())
			if child.get_script():
				print("    Script: ", child.get_script().resource_path)
			# Check for map-related methods
			if child.has_method("generate_map"):
				print("    ✅ Has generate_map()")
			if child.has_method("render_map"):
				print("    ✅ Has render_map()")
			if child.has_method("count_terrain_types"):
				print("    ✅ Has count_terrain_types()")
	
	print("=== SYSTEM REFERENCES ===")
	print("ResourceManager: ", resource_manager)
	print("BuildingSystem: ", building_system)
	print("WeatherSystem: ", weather_system)
	print("==========================")

func debug_manual_map_regen():
	"""Debug funkce pro manuální regeneraci mapy"""
	print("=== MANUAL MAP REGENERATION TEST ===")
	
	# Test current scene
	var scene = get_tree().current_scene
	if scene and scene.has_method("generate_map") and scene.has_method("render_map"):
		print("Using current scene as MapGenerator")
		scene.generate_map()
		scene.render_map()
		print("✅ Map regenerated via current scene")
		return
	
	# Test children
	if scene:
		for child in scene.get_children():
			if child.has_method("generate_map") and child.has_method("render_map"):
				print("Using child '", child.name, "' as MapGenerator")
				child.generate_map()
				child.render_map()
				print("✅ Map regenerated via child")
				return
	
	print("❌ No suitable MapGenerator found")

func debug_test_building_reset():
	"""Debug funkce pro test building reset"""
	print("=== BUILDING RESET TEST ===")
	
	var building_sys = building_system
	if building_sys:
		print("BuildingSystem found: ", building_sys.name)
		print("Before reset - Building mode: ", building_sys.is_building_mode)
		print("Before reset - Repair mode: ", building_sys.is_repair_mode)
		print("Before reset - Buildings count: ", building_sys.get_all_buildings().size())
		
		building_sys.reset_buildings()
		
		print("After reset - Building mode: ", building_sys.is_building_mode)
		print("After reset - Repair mode: ", building_sys.is_repair_mode)
		print("After reset - Buildings count: ", building_sys.get_all_buildings().size())
	else:
		print("❌ BuildingSystem not found")

func debug_show_stats():
	"""Debug funkce pro zobrazení všech statistik"""
	print("=== COMPLETE GAME STATUS ===")
	print("Game time: ", format_time(game_time))
	print("Current state: ", GameState.keys()[current_state])
	print("Buildings built: ", buildings_built)
	print("Buildings repaired: ", buildings_repaired)
	print("Disasters survived: ", disasters_survived)
	print("Victory achieved: ", victory_achieved)
	
	# Building system info
	if building_system:
		var all_buildings = building_system.get_all_buildings()
		print("Active buildings on map: ", all_buildings.size())
		
		if building_system.has_method("get_buildings_needing_repair"):
			var damaged = building_system.get_buildings_needing_repair()
			print("Buildings needing repair: ", damaged.size())
		
		print("Building mode active: ", building_system.is_building_mode)
		print("Repair mode active: ", building_system.is_repair_mode)
	else:
		print("BuildingSystem: Not connected")
	
	# Resource info
	if resource_manager and resource_manager.has_method("debug_print_resources"):
		resource_manager.debug_print_resources()
	else:
		print("ResourceManager: Not connected or no debug method")
	
	print("============================")
