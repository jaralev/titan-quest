# ===========================================
# SOUBOR: ResourceUI.gd
# ===========================================
# UI pro zobrazení zdrojů - připojte k Control node

extends Control

@onready var resource_manager: Node = get_node("/root/ResourceManager")

# UI elementy - vytvořte je v editoru nebo kódem
var resource_labels = {}
var resource_bars = {}

# Boost tlačítka
var watch_ad_button: Button
var purchase_button: Button

func _ready():
	print("ResourceUI initialized")
	create_resource_ui()
	
	# Připojte signály
	if resource_manager:
		resource_manager.resource_changed.connect(_on_resource_changed)

func create_resource_ui():
	"""Vytvoří UI pro všechny zdroje"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	add_child(main_vbox)
	
	# Nastavení pozice v levém horním rohu
	position = Vector2(10, 10)
	
	# Header s titulkem
	var header_panel = create_header_panel()
	main_vbox.add_child(header_panel)
	
	# Resource panels
	var resources_vbox = VBoxContainer.new()
	resources_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(resources_vbox)
	
	for resource_type in ResourceManager.ResourceType.values():
		var resource_panel = create_resource_panel(resource_type)
		resources_vbox.add_child(resource_panel)
	
	# Separator
	var separator = HSeparator.new()
	main_vbox.add_child(separator)
	
	# Boost buttons section
	var boost_section = create_boost_section()
	main_vbox.add_child(boost_section)

func create_header_panel() -> Control:
	"""Vytvoří header panel s titulkem"""
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(320, 35)
	
	# Styling pro header
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.3, 0.4, 0.9)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header_style.set_border_width_all(2)
	header_style.border_color = Color.CYAN
	header_panel.add_theme_stylebox_override("panel", header_style)
	
	var header_label = Label.new()
	header_label.text = "📊 COLONY RESOURCES"
	header_label.add_theme_font_size_override("font_size", 16)
	header_label.add_theme_color_override("font_color", Color.CYAN)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_panel.add_child(header_label)
	
	return header_panel

func create_resource_panel(resource_type: ResourceManager.ResourceType) -> Control:
	"""Vytvoří panel pro jeden zdroj"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 45)
	
	# Styling pro resource panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color.GRAY
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	
	# Icon + název zdroje
	var name_label = Label.new()
	name_label.text = get_resource_icon(resource_type) + " " + resource_manager.get_resource_name(resource_type)
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", get_resource_color(resource_type))
	hbox.add_child(name_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(120, 25)
	progress_bar.max_value = resource_manager.max_capacity[resource_type]
	progress_bar.value = resource_manager.current_resources[resource_type]
	
	# Styling pro progress bar
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	progress_style.corner_radius_top_left = 3
	progress_style.corner_radius_top_right = 3
	progress_style.corner_radius_bottom_left = 3
	progress_style.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("background", progress_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = get_resource_color(resource_type)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	hbox.add_child(progress_bar)
	resource_bars[resource_type] = progress_bar
	
	# Amount label
	var amount_label = Label.new()
	amount_label.custom_minimum_size = Vector2(90, 0)
	amount_label.add_theme_font_size_override("font_size", 11)
	update_amount_label(amount_label, resource_type)
	hbox.add_child(amount_label)
	resource_labels[resource_type] = amount_label
	
	return panel

func create_boost_section() -> Control:
	"""Vytvoří sekci s tlačítky pro navýšení zdrojů"""
	var boost_panel = PanelContainer.new()
	boost_panel.custom_minimum_size = Vector2(320, 80)
	
	# Styling pro boost panel
	var boost_style = StyleBoxFlat.new()
	boost_style.bg_color = Color(0.15, 0.25, 0.15, 0.9)
	boost_style.corner_radius_top_left = 8
	boost_style.corner_radius_top_right = 8
	boost_style.corner_radius_bottom_left = 8
	boost_style.corner_radius_bottom_right = 8
	boost_style.set_border_width_all(2)
	boost_style.border_color = Color.GREEN
	boost_panel.add_theme_stylebox_override("panel", boost_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	boost_panel.add_child(vbox)
	
	# Header pro boost sekci
	var boost_header = Label.new()
	boost_header.text = "💰 RESOURCE BOOST"
	boost_header.add_theme_font_size_override("font_size", 12)
	boost_header.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	boost_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(boost_header)
	
	# Buttons container
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 10)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_hbox)
	
	# Watch Ad button
	watch_ad_button = Button.new()
	watch_ad_button.text = "📺 WATCH AD\n+20 All Resources"
	watch_ad_button.custom_minimum_size = Vector2(140, 45)
	watch_ad_button.add_theme_font_size_override("font_size", 10)
	watch_ad_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Styling pro Watch Ad button
	var ad_button_style = StyleBoxFlat.new()
	ad_button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	ad_button_style.corner_radius_top_left = 6
	ad_button_style.corner_radius_top_right = 6
	ad_button_style.corner_radius_bottom_left = 6
	ad_button_style.corner_radius_bottom_right = 6
	ad_button_style.set_border_width_all(1)
	ad_button_style.border_color = Color.CYAN
	watch_ad_button.add_theme_stylebox_override("normal", ad_button_style)
	
	var ad_button_hover = ad_button_style.duplicate()
	ad_button_hover.bg_color = Color(0.3, 0.5, 0.9, 0.9)
	watch_ad_button.add_theme_stylebox_override("hover", ad_button_hover)
	
	watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	buttons_hbox.add_child(watch_ad_button)
	
	# Purchase button
	purchase_button = Button.new()
	purchase_button.text = "💎 PURCHASE\n+200 All Resources"
	purchase_button.custom_minimum_size = Vector2(140, 45)
	purchase_button.add_theme_font_size_override("font_size", 10)
	purchase_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Styling pro Purchase button
	var purchase_button_style = StyleBoxFlat.new()
	purchase_button_style.bg_color = Color(0.8, 0.4, 0.2, 0.9)
	purchase_button_style.corner_radius_top_left = 6
	purchase_button_style.corner_radius_top_right = 6
	purchase_button_style.corner_radius_bottom_left = 6
	purchase_button_style.corner_radius_bottom_right = 6
	purchase_button_style.set_border_width_all(1)
	purchase_button_style.border_color = Color.GOLD
	purchase_button.add_theme_stylebox_override("normal", purchase_button_style)
	
	var purchase_button_hover = purchase_button_style.duplicate()
	purchase_button_hover.bg_color = Color(0.9, 0.5, 0.3, 0.9)
	purchase_button.add_theme_stylebox_override("hover", purchase_button_hover)
	
	purchase_button.pressed.connect(_on_purchase_pressed)
	buttons_hbox.add_child(purchase_button)
	
	return boost_panel

func get_resource_icon(resource_type: ResourceManager.ResourceType) -> String:
	"""Vrátí emoji ikonu pro daný zdroj"""
	match resource_type:
		ResourceManager.ResourceType.ENERGY:
			return "⚡"
		ResourceManager.ResourceType.OXYGEN:
			return "🫁"
		ResourceManager.ResourceType.FOOD:
			return "🍎"
		ResourceManager.ResourceType.WATER:
			return "💧"
		ResourceManager.ResourceType.METHANE:
			return "🔥"
		ResourceManager.ResourceType.BUILDING_MATERIALS:
			return "🔧"
		_:
			return "❓"

func get_resource_color(resource_type: ResourceManager.ResourceType) -> Color:
	"""Vrátí barvu pro daný zdroj"""
	match resource_type:
		ResourceManager.ResourceType.ENERGY:
			return Color.YELLOW
		ResourceManager.ResourceType.OXYGEN:
			return Color.CYAN
		ResourceManager.ResourceType.FOOD:
			return Color.GREEN
		ResourceManager.ResourceType.WATER:
			return Color.BLUE
		ResourceManager.ResourceType.METHANE:
			return Color.ORANGE
		ResourceManager.ResourceType.BUILDING_MATERIALS:
			return Color.GRAY
		_:
			return Color.WHITE

func update_amount_label(label: Label, resource_type: ResourceManager.ResourceType):
	"""Aktualizuje text labelu s množstvím"""
	var current = resource_manager.get_resource_amount(resource_type)
	var max_amount = resource_manager.max_capacity[resource_type]
	var net_rate = resource_manager.get_net_rate(resource_type)
	var unit = resource_manager.get_resource_unit(resource_type)
	
	var rate_text = ""
	if net_rate > 0:
		rate_text = " (+%.1f/s)" % net_rate
	elif net_rate < 0:
		rate_text = " (%.1f/s)" % net_rate
	
	label.text = "%.0f/%.0f%s%s" % [current, max_amount, unit, rate_text]
	
	# Barva podle stavu
	if net_rate < 0 and current < 100:
		label.modulate = Color.RED
	elif net_rate < 0:
		label.modulate = Color.YELLOW
	elif net_rate > 0:
		label.modulate = Color.LIGHT_GREEN
	else:
		label.modulate = Color.WHITE

func _on_resource_changed(resource_type: ResourceManager.ResourceType, amount: float):
	"""Callback při změně zdroje"""
	if resource_type in resource_bars:
		resource_bars[resource_type].value = amount
	
	if resource_type in resource_labels:
		update_amount_label(resource_labels[resource_type], resource_type)

# BOOST BUTTON CALLBACKS
func _on_watch_ad_pressed():
	"""Callback pro tlačítko Watch Ad"""
	print("=== Watch Ad pressed ===")
	
	# Dočasně zakáži tlačítko
	watch_ad_button.disabled = true
	watch_ad_button.text = "📺 LOADING AD..."
	
	# Simulace načítání reklamy (2 sekundy)
	await get_tree().create_timer(2.0).timeout
	
	# Přidej zdroje
	boost_all_resources(20.0, "Watch Ad")
	
	watch_ad_button.text = "Cool down"
	
	# Znovu aktivuj tlačítko po 15 sekundách (cooldown)
	await get_tree().create_timer(15.0).timeout
	
	if watch_ad_button and is_instance_valid(watch_ad_button):
		watch_ad_button.disabled = false
		watch_ad_button.text = "📺 WATCH AD\n+20 All Resources"

func _on_purchase_pressed():
	"""Callback pro tlačítko Purchase"""
	print("=== Purchase button pressed ===")
	
	# Dočasně zakáži tlačítko
	purchase_button.disabled = true
	purchase_button.text = "💎 PROCESSING..."
	
	# Simulace zpracování platby (1 sekunda)
	await get_tree().create_timer(1.0).timeout
	
	# Přidej zdroje
	boost_all_resources(200.0, "Purchase")
	
	purchase_button.text = "Cool down..."
	
	# Znovu aktivuj tlačítko po 5 sekundách
	await get_tree().create_timer(5.0).timeout
	
	if purchase_button and is_instance_valid(purchase_button):
		purchase_button.disabled = false
		purchase_button.text = "💎 PURCHASE\n+200 All Resources"

func boost_all_resources(amount: float, source: String):
	"""Přidá množství ke všem zdrojům s vizuálními efekty"""
	print("Source: ", source, ", boost: ", amount, " to all resources")
	
	# Přidej zdroje
	for resource_type in ResourceManager.ResourceType.values():
		resource_manager.add_resource(resource_type, amount)
	
	# Vizuální feedback
	show_boost_notification(amount, source)

func show_boost_notification(amount: float, source: String):
	"""Zobrazí notifikaci o navýšení zdrojů"""
	# OPRAVA 1: Přejmenování proměnné notification na boost_notification
	var boost_notification = Label.new()
	boost_notification.text = "🎉 %s: +%.0f ALL RESOURCES!" % [source.to_upper(), amount]
	boost_notification.add_theme_font_size_override("font_size", 14)
	boost_notification.add_theme_color_override("font_color", Color.GOLD)
	boost_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# OPRAVA 2: Pozice notifikace přímo pod resources panelem
	var notification_x = position.x
	var notification_y = position.y + 400  # Pod resources panelem
	boost_notification.position = Vector2(notification_x, notification_y)
	boost_notification.size = Vector2(320, 30)  # Stejná šířka jako resources panel
	
	# Styling pro notifikaci
	var notification_bg = PanelContainer.new()
	var notification_style = StyleBoxFlat.new()
	notification_style.bg_color = Color(0.1, 0.5, 0.1, 0.95)
	notification_style.corner_radius_top_left = 10
	notification_style.corner_radius_top_right = 10
	notification_style.corner_radius_bottom_left = 10
	notification_style.corner_radius_bottom_right = 10
	notification_style.set_border_width_all(2)
	notification_style.border_color = Color.GOLD
	notification_bg.add_theme_stylebox_override("panel", notification_style)
	notification_bg.position = boost_notification.position - Vector2(10, 5)
	notification_bg.size = boost_notification.size + Vector2(20, 10)
	
	# Přidej do scény
	get_tree().current_scene.add_child(notification_bg)
	get_tree().current_scene.add_child(boost_notification)
	
	# Animace
	boost_notification.modulate = Color.TRANSPARENT
	notification_bg.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.parallel().tween_property(boost_notification, "modulate", Color.WHITE, 0.3)
	tween.parallel().tween_property(notification_bg, "modulate", Color.WHITE, 0.3)
	tween.tween_interval(2.0)  # Oprava: použití tween_interval místo tween_delay
	tween.parallel().tween_property(boost_notification, "modulate", Color.TRANSPARENT, 0.5)
	tween.parallel().tween_property(notification_bg, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(func():
		if boost_notification and is_instance_valid(boost_notification):
			boost_notification.queue_free()
		if notification_bg and is_instance_valid(notification_bg):
			notification_bg.queue_free()
	)

# DEBUG FUNCTIONS
func debug_test_ad_boost():
	"""Debug funkce pro testování ad boost"""
	_on_watch_ad_pressed()

func debug_test_purchase_boost():
	"""Debug funkce pro testování purchase boost"""
	_on_purchase_pressed()

func debug_reset_cooldowns():
	"""Debug funkce pro reset cooldownů tlačítek"""
	if watch_ad_button:
		watch_ad_button.disabled = false
		watch_ad_button.text = "📺 WATCH AD\n+20 All Resources"
	
	if purchase_button:
		purchase_button.disabled = false
		purchase_button.text = "💎 PURCHASE\n+200 All Resources"
