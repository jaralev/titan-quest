# WeatherSystem.gd - Opravený systém počasí bez null reference chyb

extends Node2D

enum WeatherType {
	CLEAR,
	METHANE_STORM,
	ICE_BLIZZARD,
	TITAN_QUAKE,
	SOLAR_FLARE
}

enum DisasterSeverity {
	MINOR,
	MODERATE,
	SEVERE
}

# Weather state
var current_weather = WeatherType.CLEAR
var weather_timer = 0.0
var weather_duration = 0.0
var next_weather_check = 30.0

# Lokální weather efekty
var affected_tiles = []
var affected_center = Vector2i.ZERO
var affected_radius = 0
var storm_position = Vector2i.ZERO
var storm_direction = Vector2.ZERO

# Visual effects - simplified approach without bind
var weather_effects = []
var active_tweens = []
var shake_tween: Tween
var storm_move_timer = 0.0
var weather_active = false

# Pending rain drops queue for creation
var pending_rain_containers = []

# Weather effects tracking
var active_weather_effects = {}
var weather_start_time = 0.0
var game_time = 0.0

# Reference na ostatní systémy
@onready var building_system: Node2D = get_node("../BuildingSystem")
@onready var resource_manager: Node = get_node("/root/ResourceManager")
@onready var map_generator: Node2D = get_node("../")

# Signály
signal weather_changed(weather_type: WeatherType, severity: DisasterSeverity)
signal building_damaged(building_id: int, damage_percent: float)
signal building_destroyed(building_id: int)
signal weather_effect_started(effect_type: String, severity: DisasterSeverity)
signal weather_effect_ended(effect_type: String)

func _ready():
	print("Enhanced WeatherSystem initialized")
	weather_timer = 60.0

func _process(delta):
	weather_timer -= delta
	game_time += delta
	storm_move_timer -= delta
	
	if weather_timer <= 0:
		check_weather_change()
		weather_timer = next_weather_check
	
	# Update moving storm only if weather is active
	if current_weather == WeatherType.METHANE_STORM and weather_active and storm_move_timer <= 0:
		update_storm_position()
		storm_move_timer = 2.0

func check_weather_change():
	"""Zkontroluje a případně změní počasí"""
	var disaster_chance = 0.15
	
	if randf() < disaster_chance:
		trigger_random_disaster()
	else:
		if current_weather != WeatherType.CLEAR:
			change_weather(WeatherType.CLEAR)

func trigger_random_disaster():
	"""Spustí náhodnou katastrofu"""
	var disaster_types = [
		WeatherType.METHANE_STORM,
		WeatherType.ICE_BLIZZARD,
		WeatherType.TITAN_QUAKE,
		WeatherType.SOLAR_FLARE
	]
	
	var random_disaster = disaster_types[randi() % disaster_types.size()]
	var severity = get_random_severity()
	
	change_weather(random_disaster, severity)

func get_random_severity() -> DisasterSeverity:
	"""Náhodná severity s weight"""
	var rand = randf()
	if rand < 0.6:
		return DisasterSeverity.MINOR
	elif rand < 0.85:
		return DisasterSeverity.MODERATE
	else:
		return DisasterSeverity.SEVERE

func change_weather(new_weather: WeatherType, severity: DisasterSeverity = DisasterSeverity.MINOR):
	"""Změní počasí a spustí efekty"""
	# Clear previous effects first
	weather_active = false
	clear_weather_effects()
	
	current_weather = new_weather
	weather_duration = get_weather_duration(new_weather, severity)
	weather_start_time = get_current_time()
	weather_active = true
	
	print("NEW WEATHER: ", get_weather_name(new_weather), " ", weather_duration, " sec, ", get_severity_name(severity))
	
	# Clear old effects
	clear_active_weather_effects()
	
	# Emit signal
	weather_changed.emit(new_weather, severity)
	
	# Setup weather area and effects
	setup_weather_area(new_weather, severity)
	apply_disaster_effects(new_weather, severity)
	
	# Track active effects
	if new_weather != WeatherType.CLEAR:
		track_weather_effect(new_weather, severity)
	
	# Schedule weather end
	if weather_duration > 0:
		get_tree().create_timer(weather_duration).timeout.connect(_on_weather_ended)

func _on_weather_ended():
	"""Callback když počasí skončí"""
	weather_active = false
	change_weather(WeatherType.CLEAR)

# ========== WEATHER AREA SETUP ==========

func setup_weather_area(weather: WeatherType, severity: DisasterSeverity):
	"""Nastaví postižené oblasti podle typu počasí"""
	affected_tiles.clear()
	
	match weather:
		WeatherType.CLEAR:
			affected_tiles = []
			create_clear_effects()
		
		WeatherType.TITAN_QUAKE:
			affected_radius = randi_range(2, 5)
			affected_center = get_random_map_position()
			affected_tiles = get_circular_area(affected_center, affected_radius)
			create_earthquake_effects(severity)
		
		WeatherType.METHANE_STORM:
			affected_radius = randi_range(4, 8)
			storm_position = get_random_map_position()
			affected_center = storm_position
			storm_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			affected_tiles = get_circular_area(storm_position, affected_radius)
			create_storm_effects()
		
		WeatherType.ICE_BLIZZARD:
			affected_radius = randi_range(4, 6)
			affected_center = get_random_map_position()
			affected_tiles = get_circular_area(affected_center, affected_radius)
			create_blizzard_effects()
		
		WeatherType.SOLAR_FLARE:
			affected_tiles = get_all_map_tiles()
			create_solar_flare_effects()

func get_random_map_position() -> Vector2i:
	"""Vrátí náhodnou pozici na mapě"""
	return Vector2i(
		randi_range(5, map_generator.MAP_WIDTH - 5),
		randi_range(5, map_generator.MAP_HEIGHT - 5)
	)

func get_circular_area(center: Vector2i, radius: int) -> Array:
	"""Vrátí dlaždice v kruhovité oblasti"""
	var tiles = []
	
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if x >= 0 and x < map_generator.MAP_WIDTH and y >= 0 and y < map_generator.MAP_HEIGHT:
				var distance = Vector2(x - center.x, y - center.y).length()
				if distance <= radius:
					tiles.append(Vector2i(x, y))
	
	return tiles

func get_all_map_tiles() -> Array:
	"""Vrátí všechny dlaždice na mapě"""
	var tiles = []
	for x in range(map_generator.MAP_WIDTH):
		for y in range(map_generator.MAP_HEIGHT):
			tiles.append(Vector2i(x, y))
	return tiles

func update_storm_position():
	"""Aktualizuje pozici bouře (pro methane storm)"""
	if current_weather != WeatherType.METHANE_STORM or not weather_active:
		return
	
	# Move storm
	storm_position += Vector2i(
		int(storm_direction.x * 2),
		int(storm_direction.y * 2)
	)
	
	# Bounce off edges
	if storm_position.x <= affected_radius or storm_position.x >= map_generator.MAP_WIDTH - affected_radius:
		storm_direction.x *= -1
	if storm_position.y <= affected_radius or storm_position.y >= map_generator.MAP_HEIGHT - affected_radius:
		storm_direction.y *= -1
	
	# Clamp to map bounds
	storm_position.x = clamp(storm_position.x, affected_radius, map_generator.MAP_WIDTH - affected_radius)
	storm_position.y = clamp(storm_position.y, affected_radius, map_generator.MAP_HEIGHT - affected_radius)
	
	# Update affected area
	affected_tiles = get_circular_area(storm_position, affected_radius)
	
	# Recreate storm effects safely
	clear_storm_effects_only()
	if weather_active:
		create_storm_effects()

# ========== VISUAL EFFECTS - BEZPEČNÉ VERZE ==========

func create_earthquake_effects(severity: DisasterSeverity):
	"""Vytvoří efekt zemětřesení"""
	create_screen_shake(severity)
	
	# Simplified tile flash effect
	for tile_pos in affected_tiles:
		create_simple_tile_flash(tile_pos)

func create_screen_shake(severity: DisasterSeverity):
	"""Vytvoří efekt zatřesení obrazovky"""
	if not map_generator or not is_instance_valid(map_generator):
		return
	
	var shake_intensity = get_severity_multiplier(severity) * 5.0  # Snížena intenzita
	# var shake_duration = 1.0  # Zkrácena délka
	
	# Kill previous shake
	if shake_tween and is_instance_valid(shake_tween):
		shake_tween.kill()
	
	shake_tween = create_tween()
	if not shake_tween:
		return
	
	var original_pos = map_generator.position
	
	# Simple shake - up/down/left/right
	for i in range(4):
		var shake_offset = Vector2.ZERO
		match i % 4:
			0: shake_offset = Vector2(shake_intensity, 0)
			1: shake_offset = Vector2(0, shake_intensity)
			2: shake_offset = Vector2(-shake_intensity, 0)
			3: shake_offset = Vector2(0, -shake_intensity)
		
		shake_tween.tween_property(map_generator, "position", original_pos + shake_offset, 0.1)
	
	shake_tween.tween_property(map_generator, "position", original_pos, 0.1)
	active_tweens.append(shake_tween)

func create_simple_tile_flash(tile_pos: Vector2i):
	"""Vytvoří jednoduchý blikající efekt"""
	var flash_rect = ColorRect.new()
	flash_rect.color = Color.RED
	flash_rect.position = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	flash_rect.size = Vector2(64, 64)
	flash_rect.z_index = 100
	flash_rect.modulate.a = 0.0
	
	get_parent().add_child(flash_rect)
	weather_effects.append(flash_rect)
	
	# Simple flash animation without bind
	var flash_tween = create_tween()
	if flash_tween:
		flash_tween.tween_property(flash_rect, "modulate:a", 0.7, 0.3)
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.3)
		flash_tween.tween_callback(flash_rect.queue_free)  # Direct method call
		active_tweens.append(flash_tween)

# Remove the callback function that was causing issues
# func _handle_flash_complete(flash_rect: ColorRect):

func create_storm_effects():
	"""Vytvoří efekt metanové bouře s animovanými kapkami"""
	if not weather_active:
		return
	
	# Create animated rain for all affected tiles
	for tile_pos in affected_tiles:
		create_animated_rain_effect(tile_pos)

func create_animated_rain_effect(tile_pos: Vector2i):
	"""Vytvoří animovaný efekt deště s jednoduchými callbacky"""
	var rain_container = Node2D.new()
	rain_container.position = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	rain_container.z_index = 90
	rain_container.name = "RainContainer_" + str(tile_pos.x) + "_" + str(tile_pos.y)
	
	get_parent().add_child(rain_container)
	weather_effects.append(rain_container)
	
	# Create 4 rain drops per tile with simple timer approach
	for i in range(4):
		var delay = randf_range(0.0, 1.0)
		# Add to pending queue
		pending_rain_containers.append(rain_container)
		
		# Use simple timer without bind
		var timer = Timer.new()
		timer.wait_time = delay
		timer.one_shot = true
		timer.timeout.connect(_process_pending_rain_drops)
		add_child(timer)
		timer.start()

func _process_pending_rain_drops():
	"""Process one pending rain container"""
	if pending_rain_containers.size() > 0:
		var container = pending_rain_containers.pop_front()
		if container and is_instance_valid(container) and weather_active:
			create_safe_rain_drop(container)

func create_safe_rain_drop(parent: Node2D):
	"""Vytvoří bezpečnou kapku deště"""
	if not parent or not is_instance_valid(parent) or not weather_active:
		return
	
	if current_weather != WeatherType.METHANE_STORM:
		return
	
	var rain_line = Line2D.new()
	rain_line.add_point(Vector2.ZERO)
	rain_line.add_point(Vector2(2, 10))
	rain_line.default_color = Color(0.3, 0.2, 0.1, 0.8)
	rain_line.width = 3
	rain_line.name = "RainDrop_" + str(randi())
	
	# Random position on top edge
	rain_line.position = Vector2(
		randf_range(0, 64),
		-15
	)
	
	parent.add_child(rain_line)
	
	# Animate with safety checks
	animate_safe_rain_drop(rain_line, parent)

func animate_safe_rain_drop(rain_line: Line2D, parent: Node2D):
	"""Zjednodušená animace kapky deště bez bind callbacků"""
	if not rain_line or not is_instance_valid(rain_line) or not weather_active:
		return
	
	if not parent or not is_instance_valid(parent):
		if rain_line and is_instance_valid(rain_line):
			rain_line.queue_free()
		return
	
	if current_weather != WeatherType.METHANE_STORM:
		if rain_line and is_instance_valid(rain_line):
			rain_line.queue_free()
		return
	
	# Create simple fall animation
	var fall_duration = randf_range(0.6, 1.0)
	var fall_tween = create_tween()
	
	if not fall_tween:
		if rain_line and is_instance_valid(rain_line):
			rain_line.queue_free()
		return
	
	active_tweens.append(fall_tween)
	
	# Just fall down, no complex callbacks
	fall_tween.tween_property(rain_line, "position:y", 75, fall_duration)
	
	# Simple finish - remove after fall
	fall_tween.tween_callback(rain_line.queue_free)

# Remove all the complex callback functions that were causing issues
# func _handle_rain_drop_impact(rain_line: Line2D):
# func _handle_rain_drop_fade(rain_line: Line2D):  
# func _handle_rain_drop_respawn(rain_line: Line2D):

func create_blizzard_effects():
	"""Vytvoří efekt ledové bouře"""
	for tile_pos in affected_tiles:
		create_frost_effect(tile_pos)

func create_frost_effect(tile_pos: Vector2i):
	"""Vytvoří efekt omrznutí na dlaždici"""
	var frost_overlay = ColorRect.new()
	frost_overlay.color = Color(0.8, 0.9, 1.0, 0.4)
	frost_overlay.position = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	frost_overlay.size = Vector2(64, 64)
	frost_overlay.z_index = 80
	frost_overlay.modulate.a = 0.0
	
	get_parent().add_child(frost_overlay)
	weather_effects.append(frost_overlay)
	
	# Simple fade in
	var fade_tween = create_tween()
	if fade_tween:
		fade_tween.tween_property(frost_overlay, "modulate:a", 1.0, 1.0)
		active_tweens.append(fade_tween)

func create_solar_flare_effects():
	"""Vytvoří efekt sluneční erupce na celé mapě"""
	# Solar flare affects ALL tiles, not just a sample
	for tile_pos in affected_tiles:
		create_orange_effect(tile_pos)

func create_orange_effect(tile_pos: Vector2i):
	"""Vytvoří oranžový efekt na dlaždici"""
	var orange_overlay = ColorRect.new()
	orange_overlay.color = Color(1.0, 0.6, 0.2, 0.3)
	orange_overlay.position = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	orange_overlay.size = Vector2(64, 64)
	orange_overlay.z_index = 80
	orange_overlay.modulate.a = 0.0
	
	get_parent().add_child(orange_overlay)
	weather_effects.append(orange_overlay)
	
	# Simple pulsing
	var pulse_tween = create_tween()
	if pulse_tween and weather_active:
		pulse_tween.set_loops()
		pulse_tween.tween_property(orange_overlay, "modulate:a", 0.5, 1.0)
		pulse_tween.tween_property(orange_overlay, "modulate:a", 0.2, 1.0)
		active_tweens.append(pulse_tween)

func create_clear_effects():
	"""Vyčistí všechny weather efekty"""
	clear_weather_effects()

# ========== BEZPEČNÝ CLEANUP ==========

func safe_remove_effect(effect: Node):
	"""Bezpečně odstraní efekt"""
	if effect and is_instance_valid(effect):
		if effect in weather_effects:
			weather_effects.erase(effect)
		effect.queue_free()

func clear_storm_effects_only():
	"""Vymaže pouze storm efekty pro update pozice"""
	var storm_effects_to_remove = []
	
	for effect in weather_effects:
		if effect and is_instance_valid(effect):
			if effect.name.begins_with("RainContainer_"):
				storm_effects_to_remove.append(effect)
	
	# Stop tweens for storm effects
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			# Check if tween is animating storm effect
			var targets = tween.get_property("") if tween.has_method("get_property") else []
			for target in targets if targets is Array else []:
				if target and is_instance_valid(target) and target.get_parent() and target.get_parent().name.begins_with("RainContainer_"):
					tween.kill()
					break
	
	# Remove storm effects
	for effect in storm_effects_to_remove:
		safe_remove_effect(effect)

func clear_weather_effects():
	"""Bezpečně vymaže všechny vizuální efekty počasí"""
	# Stop all active tweens first
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
	
	# Remove all weather effects
	for effect in weather_effects:
		if effect and is_instance_valid(effect):
			effect.queue_free()
	weather_effects.clear()
	
	# Stop screen shake
	if shake_tween and is_instance_valid(shake_tween):
		shake_tween.kill()
		shake_tween = null
	
	# Reset map position
	if map_generator and is_instance_valid(map_generator):
		map_generator.position = Vector2.ZERO

# ========== BUILDING EFFECTS ==========

func get_affected_buildings() -> Array:
	"""Vrátí seznam budov postižených počasím"""
	if not building_system:
		return []
	
	var affected_buildings = []
	var processed_buildings = {}
	
	for tile_pos in affected_tiles:
		if building_system.is_building_at_position(tile_pos):
			var building_data = building_system.get_building_at_position(tile_pos)
			var building_id = building_data.get("id", -1)
			
			if building_id != -1 and not building_id in processed_buildings:
				affected_buildings.append(building_data.get("position", tile_pos))
				processed_buildings[building_id] = true
	
	return affected_buildings

# ========== HELPER FUNKCE ==========

func get_current_time() -> float:
	"""Bezpečné získání aktuálního času"""
	if Time.has_method("get_unix_time_from_system"):
		return Time.get_unix_time_from_system()
	else:
		return game_time

func get_weather_name(weather: WeatherType) -> String:
	match weather:
		WeatherType.CLEAR: return "Clear Sky"
		WeatherType.METHANE_STORM: return "Methane Storm"
		WeatherType.ICE_BLIZZARD: return "Ice Blizzard"
		WeatherType.TITAN_QUAKE: return "Titan Quake"
		WeatherType.SOLAR_FLARE: return "Solar Flare"
		_: return "Unknown"

func get_severity_name(severity: DisasterSeverity) -> String:
	match severity:
		DisasterSeverity.MINOR: return "Minor"
		DisasterSeverity.MODERATE: return "Moderate"
		DisasterSeverity.SEVERE: return "Severe"
		_: return "Unknown"

func get_weather_duration(weather: WeatherType, severity: DisasterSeverity) -> float:
	var base_duration = 0.0
	
	match weather:
		WeatherType.CLEAR: 
			base_duration = 0.0
		WeatherType.METHANE_STORM: 
			base_duration = 45.0
		WeatherType.ICE_BLIZZARD: 
			base_duration = 60.0
		WeatherType.TITAN_QUAKE: 
			base_duration = 15.0
		WeatherType.SOLAR_FLARE: 
			base_duration = 30.0
	
	var severity_multiplier = get_severity_multiplier(severity)
	return base_duration * severity_multiplier

func get_severity_multiplier(severity: DisasterSeverity) -> float:
	match severity:
		DisasterSeverity.MINOR: return 1.0
		DisasterSeverity.MODERATE: return 1.5
		DisasterSeverity.SEVERE: return 2.5
		_: return 1.0

# ========== RESOURCE MANAGEMENT ==========

func get_resource_type_enum(resource_name: String) -> ResourceManager.ResourceType:
	match resource_name.to_upper():
		"ENERGY": return ResourceManager.ResourceType.ENERGY
		"FOOD": return ResourceManager.ResourceType.FOOD  
		"METHANE": return ResourceManager.ResourceType.METHANE
		"WATER": return ResourceManager.ResourceType.WATER
		"OXYGEN": return ResourceManager.ResourceType.OXYGEN
		"BUILDING_MATERIALS": return ResourceManager.ResourceType.BUILDING_MATERIALS
		_: return ResourceManager.ResourceType.ENERGY

func safe_add_resource(resource_name: String, amount: float) -> bool:
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.current_resources[resource_type] += amount
	resource_manager.current_resources[resource_type] = min(
		resource_manager.current_resources[resource_type], 
		resource_manager.max_capacity[resource_type]
	)
	resource_manager.resource_changed.emit(resource_type, resource_manager.current_resources[resource_type])
	return true

func safe_remove_resource(resource_name: String, amount: float) -> bool:
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.current_resources[resource_type] = max(0, 
		resource_manager.current_resources[resource_type] - amount)
	resource_manager.resource_changed.emit(resource_type, resource_manager.current_resources[resource_type])
	return true

func safe_add_consumption(resource_name: String, amount: float) -> bool:
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.add_consumption(resource_type, amount)
	return true

func safe_remove_consumption(resource_name: String, amount: float) -> bool:
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.remove_consumption(resource_type, amount)
	return true

# ========== WEATHER EFFECTS TRACKING ==========

func track_weather_effect(weather_type: WeatherType, severity: DisasterSeverity):
	var effect_name = get_weather_name(weather_type).to_lower().replace(" ", "_")
	active_weather_effects[effect_name] = {
		"weather_type": weather_type,
		"severity": severity,
		"start_time": get_current_time(),
		"duration": weather_duration,
		"affected_area": affected_tiles.duplicate()
	}

func clear_active_weather_effects():
	for effect_name in active_weather_effects.keys():
		weather_effect_ended.emit(effect_name)
	active_weather_effects.clear()

func get_weather_effect_on_building(_building_type: int) -> Dictionary:
	var effects = {}
	
	for effect_name in active_weather_effects:
		var effect_data = active_weather_effects[effect_name]
		var weather_type = effect_data.get("weather_type", WeatherType.CLEAR)
		var severity = effect_data.get("severity", DisasterSeverity.MINOR)
		
		match weather_type:
			WeatherType.ICE_BLIZZARD:
				effects["energy_consumption"] = {
					"description": "Increased energy consumption due to cold",
					"modifier": get_severity_multiplier(severity),
					"severity": get_severity_name(severity)
				}
			WeatherType.METHANE_STORM:
				effects["storm_exposure"] = {
					"description": "Exposed to methane storm damage",
					"risk": "High" if severity == DisasterSeverity.SEVERE else "Medium",
					"severity": get_severity_name(severity)
				}
			WeatherType.SOLAR_FLARE:
				effects["electronics_disruption"] = {
					"description": "Electronic systems disrupted",
					"impact": "Critical" if severity == DisasterSeverity.SEVERE else "Moderate",
					"severity": get_severity_name(severity)
				}
			WeatherType.TITAN_QUAKE:
				effects["structural_stress"] = {
					"description": "Building under seismic stress",
					"risk": "Extreme" if severity == DisasterSeverity.SEVERE else "High",
					"severity": get_severity_name(severity)
				}
	
	return effects

func get_building_weather_status(building_type: int) -> String:
	var effects = get_weather_effect_on_building(building_type)
	
	if effects.is_empty():
		return "Normal operations"
	
	var status_parts = []
	for effect_name in effects:
		var effect = effects[effect_name]
		status_parts.append(effect["description"])
	
	return " • ".join(status_parts)

func get_building_weather_status_color(building_type: int) -> String:
	var effects = get_weather_effect_on_building(building_type)
	
	if effects.is_empty():
		return "green"
	
	for effect_name in effects:
		var effect = effects[effect_name]
		if "risk" in effect:
			match effect["risk"]:
				"Extreme": return "red"
				"High": return "orange"
		if "impact" in effect:
			match effect["impact"]:
				"Critical": return "red"
				"Moderate": return "orange"
	
	return "yellow"

# ========== DISASTER EFFECTS ==========

func apply_disaster_effects(weather: WeatherType, severity: DisasterSeverity):
	match weather:
		WeatherType.METHANE_STORM:
			apply_methane_storm_effects(severity)
		WeatherType.ICE_BLIZZARD:
			apply_ice_blizzard_effects(severity)
		WeatherType.TITAN_QUAKE:
			apply_titan_quake_effects(severity)
		WeatherType.SOLAR_FLARE:
			apply_solar_flare_effects(severity)

func apply_methane_storm_effects(severity: DisasterSeverity):
	var damage_chance = get_damage_chance(severity)
	var affected_buildings = get_affected_buildings()
	var building_count = damage_buildings_in_area(affected_buildings, damage_chance, 0.1, 0.3)
	
	var methane_bonus = 20.0 * get_severity_multiplier(severity)
	if safe_add_resource("METHANE", methane_bonus):
		print("Methane storm: +", methane_bonus, " methane, ", building_count, " buildings in storm area damaged")

func apply_ice_blizzard_effects(severity: DisasterSeverity):
	var energy_penalty = 3.0 * get_severity_multiplier(severity)
	
	if safe_add_consumption("ENERGY", energy_penalty):
		print("Ice blizzard: +", energy_penalty, " energy consumption")
		
		active_weather_effects["ice_blizzard_consumption"] = {
			"type": "energy_consumption",
			"amount": energy_penalty,
			"start_time": get_current_time()
		}
		
		# Simple timer without bind
		if weather_duration > 0:
			var timer = Timer.new()
			timer.wait_time = weather_duration
			timer.one_shot = true
			timer.timeout.connect(_end_ice_blizzard_simple)
			add_child(timer)
			timer.start()
		
		weather_effect_started.emit("ice_blizzard_consumption", severity)

func _end_ice_blizzard_simple():
	"""Simple callback pro konec ledové bouře"""
	# Get penalty from active effects instead of parameter
	var effect_data = active_weather_effects.get("ice_blizzard_consumption", {})
	var energy_penalty = effect_data.get("amount", 0.0)
	
	if resource_manager and is_instance_valid(resource_manager) and energy_penalty > 0:
		safe_remove_consumption("ENERGY", energy_penalty)
	
	if "ice_blizzard_consumption" in active_weather_effects:
		active_weather_effects.erase("ice_blizzard_consumption")
	
	weather_effect_ended.emit("ice_blizzard_consumption")

# Remove the old callback function
# func _handle_ice_blizzard_end():

func apply_titan_quake_effects(severity: DisasterSeverity):
	var damage_chance = get_damage_chance(severity) * 1.5
	var affected_buildings = get_affected_buildings()
	var building_count = damage_buildings_in_area(affected_buildings, damage_chance, 0.2, 0.8)
	print("Titan quake: ", building_count, " buildings in quake area heavily damaged")

func apply_solar_flare_effects(severity: DisasterSeverity):
	var energy_loss = 50.0 * get_severity_multiplier(severity)
	
	if safe_remove_resource("ENERGY", energy_loss):
		print("Solar flare: -", energy_loss, " energy lost across entire map")

func damage_buildings_in_area(building_positions: Array, chance: float, min_damage: float, max_damage: float) -> int:
	var damaged_count = 0
	
	if not building_system:
		return 0
	
	for building_pos in building_positions:
		if randf() < chance:
			var damage = randf_range(min_damage, max_damage)
			
			if damage > 0.5:
				destroy_building_at_position(building_pos)
				damaged_count += 1
			else:
				damage_building_at_position(building_pos, damage)
				damaged_count += 1
	
	return damaged_count

func destroy_building_at_position(building_pos: Vector2):
	if building_system and building_system.has_method("destroy_building_at_position"):
		var tile_pos = Vector2i(int(building_pos.x), int(building_pos.y))
		building_system.destroy_building_at_position(tile_pos)
		building_destroyed.emit(building_pos.x * 1000 + building_pos.y, 1.0)
		print("Building destroyed at: ", building_pos)

func damage_building_at_position(building_pos: Vector2, damage_percent: float):
	if building_system and building_system.has_method("damage_building_at_position"):
		var tile_pos = Vector2i(int(building_pos.x), int(building_pos.y))
		building_system.damage_building_at_position(tile_pos, damage_percent)
		building_damaged.emit(building_pos.x * 1000 + building_pos.y, damage_percent)
		print("Building damaged at: ", building_pos, " (", damage_percent * 100, "%)")

func get_damage_chance(severity: DisasterSeverity) -> float:
	match severity:
		DisasterSeverity.MINOR: return 0.1
		DisasterSeverity.MODERATE: return 0.25
		DisasterSeverity.SEVERE: return 0.4
		_: return 0.1

# ========== PUBLIC API ==========

func get_current_weather() -> WeatherType:
	return current_weather

func get_weather_remaining_time() -> float:
	return weather_duration

func get_affected_tiles() -> Array:
	return affected_tiles.duplicate()

func get_affected_center() -> Vector2i:
	return affected_center

func get_affected_radius() -> int:
	return affected_radius

func is_tile_affected(tile_pos: Vector2i) -> bool:
	return tile_pos in affected_tiles

func is_building_affected(building_pos: Vector2i) -> bool:
	if not building_system or not building_system.is_building_at_position(building_pos):
		return false
	
	var building_data = building_system.get_building_at_position(building_pos)
	var building_position = building_data.get("position", building_pos)
	var building_type = building_data.get("type", -1)
	var building_def = building_system.building_definitions.get(building_type, {})
	var building_size = building_def.get("size", Vector2i(1, 1))
	
	# Zkontroluj zda jakákoliv část budovy je v postižené oblasti
	for x in range(building_position.x, building_position.x + building_size.x):
		for y in range(building_position.y, building_position.y + building_size.y):
			if Vector2i(x, y) in affected_tiles:
				return true
	
	return false

func force_weather(weather: WeatherType, severity: DisasterSeverity = DisasterSeverity.MINOR):
	change_weather(weather, severity)

func is_weather_active() -> bool:
	return current_weather != WeatherType.CLEAR and weather_active

func get_current_severity() -> DisasterSeverity:
	return DisasterSeverity.MINOR

# ========== DEBUG FUNKCE ==========

func debug_trigger_methane_storm():
	force_weather(WeatherType.METHANE_STORM, DisasterSeverity.MODERATE)

func debug_trigger_ice_blizzard():
	force_weather(WeatherType.ICE_BLIZZARD, DisasterSeverity.MODERATE)

func debug_trigger_titan_quake():
	force_weather(WeatherType.TITAN_QUAKE, DisasterSeverity.SEVERE)

func debug_trigger_solar_flare():
	force_weather(WeatherType.SOLAR_FLARE, DisasterSeverity.MODERATE)

func debug_show_affected_area():
	print("=== WEATHER DEBUG INFO ===")
	print("Current weather: ", get_weather_name(current_weather))
	print("Weather active: ", weather_active)
	print("Affected center: ", affected_center)
	print("Affected radius: ", affected_radius)
	print("Affected tiles count: ", affected_tiles.size())
	print("Affected buildings: ", get_affected_buildings().size())
	print("Active effects count: ", weather_effects.size())
	print("Active tweens count: ", active_tweens.size())
	
	if current_weather == WeatherType.METHANE_STORM:
		print("Storm position: ", storm_position)
		print("Storm direction: ", storm_direction)

# ========== RESET FUNKCE ==========

func reset_weather():
	"""Resetuje weather systém"""
	print("Resetting weather system...")
	
	# Stop all weather activity
	weather_active = false
	
	# Clear all effects and tweens
	clear_weather_effects()
	clear_active_weather_effects()
	
	# Wait for cleanup
	await get_tree().process_frame
	
	# Reset all variables
	current_weather = WeatherType.CLEAR
	weather_timer = 60.0
	weather_duration = 0.0
	
	affected_tiles.clear()
	affected_center = Vector2i.ZERO
	affected_radius = 0
	storm_position = Vector2i.ZERO
	storm_direction = Vector2.ZERO
	storm_move_timer = 0.0
	
	# Ensure map position is reset
	if map_generator and is_instance_valid(map_generator):
		map_generator.position = Vector2.ZERO
	
	print("Weather system reset completed")

# ========== CLEANUP ON EXIT ==========

func _exit_tree():
	"""Cleanup při ukončení"""
	weather_active = false
	clear_weather_effects()
	clear_active_weather_effects()
	
	if map_generator and is_instance_valid(map_generator):
		map_generator.position = Vector2.ZERO
