extends Control

@onready var weather_system: Node = get_node("../../WeatherSystem")
var weather_label: Label

func _ready():
	create_weather_ui()
	if weather_system:
		weather_system.weather_changed.connect(_on_weather_changed)
	
	# Zajistit vysokou prioritu pro input
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event):
	"""Zpracování kláves s vysokou prioritou - obchází focus systém"""
	if event.pressed:
		match event.keycode:
			KEY_TAB:
				if Input.is_key_pressed(KEY_SHIFT):
					# Shift+Tab = Clear weather
					if weather_system:
						weather_system.force_weather(weather_system.WeatherType.CLEAR)
				else:
					# Tab = Random weather
					if weather_system:
						weather_system.trigger_random_disaster()
				get_viewport().set_input_as_handled()
			
			KEY_F1:
				if weather_system:
					weather_system.debug_trigger_methane_storm()
				get_viewport().set_input_as_handled()
			
			KEY_F2:
				if weather_system:
					weather_system.debug_trigger_ice_blizzard()
				get_viewport().set_input_as_handled()
			
			KEY_F3:
				if weather_system:
					weather_system.debug_trigger_titan_quake()
				get_viewport().set_input_as_handled()
			
			KEY_F4:
				if weather_system:
					weather_system.debug_trigger_solar_flare()
				get_viewport().set_input_as_handled()

func create_weather_ui():
	# Kontejner pro weather info
	var weather_panel = PanelContainer.new()
	weather_panel.position = Vector2(10, get_viewport().size.y - 100) # levy dolni roh
	
	# Styling panelu
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Tmavé poloprůhledné pozadí
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	weather_panel.add_theme_stylebox_override("panel", style)
	
	# VBox layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	# Weather label
	weather_label = Label.new()
	weather_label.text = "Weather: Clear Sky"
	weather_label.add_theme_font_size_override("font_size", 16)
	weather_label.add_theme_color_override("font_color", Color.WHITE)
	weather_label.add_theme_constant_override("outline_size", 1)
	weather_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Nápověda
	var help_label = Label.new()
	help_label.text = "Tab: Random | Shift+Tab: Clear | F1-F4: Specific"
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	
	# Přidání do kontejneru
	vbox.add_child(weather_label)
	vbox.add_child(help_label)
	weather_panel.add_child(vbox)
	add_child(weather_panel)
	
	# Nastavit, aby UI neinterferovalo s myší
	weather_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_weather_changed(weather_type, severity):
	if not weather_system:
		return
	
	var weather_name = weather_system.get_weather_name(weather_type)
	var severity_name = weather_system.get_severity_name(severity)
	
	weather_label.text = "Weather: %s (%s)" % [weather_name, severity_name]
	
	# Barevné rozlišení
	match weather_type:
		0:  # CLEAR
			weather_label.modulate = Color.WHITE
		1:  # METHANE_STORM
			weather_label.modulate = Color.ORANGE
		2:  # ICE_BLIZZARD
			weather_label.modulate = Color.CYAN
		3:  # TITAN_QUAKE
			weather_label.modulate = Color.RED
		4:  # SOLAR_FLARE
			weather_label.modulate = Color.YELLOW
		_:
			weather_label.modulate = Color.WHITE
