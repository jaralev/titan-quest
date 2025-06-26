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
	"""Restart hry"""
	print("Restarting game...")
	get_tree().reload_current_scene()

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

func reset_statistics():
	"""Resetuje herní statistiky"""
	game_time = 0.0
	buildings_built = 0
	buildings_repaired = 0
	disasters_survived = 0
	victory_achieved = false
	current_state = GameState.PLAYING
	
	# Skryj victory screen pokud je zobrazený
	if victory_screen and victory_screen.visible:
		victory_screen.visible = false
	
	print("Game statistics reset")

func get_statistics() -> Dictionary:
	return {
		"game_time": game_time,
		"buildings_built": buildings_built,
		"buildings_repaired": buildings_repaired,
		"disasters_survived": disasters_survived
	}

# Debug functions
func debug_trigger_victory():
	"""Debug funkce pro spuštění vítězství"""
	_on_victory_condition_met()

func debug_show_stats():
	"""Debug funkce pro zobrazení statistik"""
	print("=== GAME STATISTICS ===")
	print("Game time: ", format_time(game_time))
	print("Buildings built: ", buildings_built)
	print("Buildings repaired: ", buildings_repaired)
	print("Disasters survived: ", disasters_survived)
	print("Victory achieved: ", victory_achieved)
