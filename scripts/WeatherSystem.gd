# Hlavní systém pro počasí a katastrofy

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
var next_weather_check = 30.0  # Check každých 30 sekund

# Weather effects tracking
var active_weather_effects = {}  # Sleduje aktivní efekty počasí
var weather_start_time = 0.0
var game_time = 0.0  # Fallback pro time tracking

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
	print("WeatherSystem initialized")
	# Prvotní počasí za 60 sekund
	weather_timer = 60.0

func _process(delta):
	weather_timer -= delta
	game_time += delta  # Fallback time tracking
	
	if weather_timer <= 0:
		check_weather_change()
		weather_timer = next_weather_check

func check_weather_change():
	"""Zkontroluje a případně změní počasí"""
	# Pravděpodobnost disaster events
	var disaster_chance = 0.15  # 15% šance každých 30 sekund
	
	if randf() < disaster_chance:
		trigger_random_disaster()
	else:
		# Vrať se k normálnímu počasí
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

func get_current_time() -> float:
	"""Bezpečné získání aktuálního času"""
	# Zkus nejdřív Godot 4 Time API
	if Time.has_method("get_unix_time_from_system"):
		return Time.get_unix_time_from_system()
	# Fallback na game_time
	else:
		return game_time

func change_weather(new_weather: WeatherType, severity: DisasterSeverity = DisasterSeverity.MINOR):
	"""Změní počasí a spustí efekty"""
	current_weather = new_weather
	weather_duration = get_weather_duration(new_weather, severity)
	weather_start_time = get_current_time()
	
	print("=== WEATHER CHANGE ===")
	print("New weather: ", get_weather_name(new_weather))
	print("Severity: ", get_severity_name(severity))
	print("Duration: ", weather_duration, " seconds")
	
	# Clear old effects
	clear_active_weather_effects()
	
	# Emit signal
	weather_changed.emit(new_weather, severity)
	
	# Spusť efekty katastrofy
	apply_disaster_effects(new_weather, severity)
	
	# Track active effects
	if new_weather != WeatherType.CLEAR:
		track_weather_effect(new_weather, severity)

# ========== CHYBĚJÍCÍ HELPER FUNKCE ==========

func get_weather_name(weather: WeatherType) -> String:
	"""Vrátí název počasí"""
	match weather:
		WeatherType.CLEAR: return "Clear Sky"
		WeatherType.METHANE_STORM: return "Methane Storm"
		WeatherType.ICE_BLIZZARD: return "Ice Blizzard"
		WeatherType.TITAN_QUAKE: return "Titan Quake"
		WeatherType.SOLAR_FLARE: return "Solar Flare"
		_: return "Unknown"

func get_severity_name(severity: DisasterSeverity) -> String:
	"""Vrátí název severity"""
	match severity:
		DisasterSeverity.MINOR: return "Minor"
		DisasterSeverity.MODERATE: return "Moderate"
		DisasterSeverity.SEVERE: return "Severe"
		_: return "Unknown"

func get_weather_duration(weather: WeatherType, severity: DisasterSeverity) -> float:
	"""Vrátí délku trvání počasí v sekundách"""
	var base_duration = 0.0
	
	match weather:
		WeatherType.CLEAR: 
			base_duration = 0.0  # Clear počasí netrvá
		WeatherType.METHANE_STORM: 
			base_duration = 45.0
		WeatherType.ICE_BLIZZARD: 
			base_duration = 60.0
		WeatherType.TITAN_QUAKE: 
			base_duration = 15.0  # Krátké ale intenzivní
		WeatherType.SOLAR_FLARE: 
			base_duration = 30.0
	
	# Severity ovlivňuje délku
	var severity_multiplier = get_severity_multiplier(severity)
	return base_duration * severity_multiplier

# ========== RESOURCE MANAGEMENT HELPERS ==========

func get_resource_type_enum(resource_name: String) -> ResourceManager.ResourceType:
	"""Vrátí správný enum pro typ zdroje"""
	match resource_name.to_upper():
		"ENERGY": return ResourceManager.ResourceType.ENERGY
		"FOOD": return ResourceManager.ResourceType.FOOD  
		"METHANE": return ResourceManager.ResourceType.METHANE
		"WATER": return ResourceManager.ResourceType.WATER
		"OXYGEN": return ResourceManager.ResourceType.OXYGEN
		"BUILDING_MATERIALS": return ResourceManager.ResourceType.BUILDING_MATERIALS
		_: return ResourceManager.ResourceType.ENERGY

func safe_add_resource(resource_name: String, amount: float) -> bool:
	"""Bezpečně přidá zdroj"""
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	
	# Přidej přímo do current_resources
	resource_manager.current_resources[resource_type] += amount
	
	# Clamp to max capacity
	resource_manager.current_resources[resource_type] = min(
		resource_manager.current_resources[resource_type], 
		resource_manager.max_capacity[resource_type]
	)
	
	# Emit signal
	resource_manager.resource_changed.emit(resource_type, resource_manager.current_resources[resource_type])
	
	return true

func safe_remove_resource(resource_name: String, amount: float) -> bool:
	"""Bezpečně odebere zdroj"""
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	
	# Odeber z current_resources
	resource_manager.current_resources[resource_type] = max(0, 
		resource_manager.current_resources[resource_type] - amount)
	
	# Emit signal
	resource_manager.resource_changed.emit(resource_type, resource_manager.current_resources[resource_type])
	
	return true

func safe_add_consumption(resource_name: String, amount: float) -> bool:
	"""Bezpečně přidá spotřebu"""
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.add_consumption(resource_type, amount)
	return true

func safe_remove_consumption(resource_name: String, amount: float) -> bool:
	"""Bezpečně odebere spotřebu"""
	if not resource_manager:
		return false
	
	var resource_type = get_resource_type_enum(resource_name)
	resource_manager.remove_consumption(resource_type, amount)
	return true

# ========== WEATHER EFFECTS TRACKING ==========

func track_weather_effect(weather_type: WeatherType, severity: DisasterSeverity):
	"""Sleduje aktivní weather efekt"""
	var effect_name = get_weather_name(weather_type).to_lower().replace(" ", "_")
	active_weather_effects[effect_name] = {
		"weather_type": weather_type,
		"severity": severity,
		"start_time": get_current_time(),
		"duration": weather_duration
	}

func clear_active_weather_effects():
	"""Vyčistí všechny aktivní weather efekty"""
	for effect_name in active_weather_effects.keys():
		weather_effect_ended.emit(effect_name)
	active_weather_effects.clear()

func get_active_weather_effects() -> Dictionary:
	"""Vrátí slovník aktivních weather efektů"""
	return active_weather_effects

func get_weather_effect_on_building(building_type: int) -> Dictionary:
	"""Vrátí jak počasí ovlivňuje konkrétní typ budovy"""
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
	"""Vrátí weather status pro budovu jako text"""
	var effects = get_weather_effect_on_building(building_type)
	
	if effects.is_empty():
		return "Normal operations"
	
	var status_parts = []
	for effect_name in effects:
		var effect = effects[effect_name]
		status_parts.append(effect["description"])
	
	return " • ".join(status_parts)

func get_building_weather_status_color(building_type: int) -> String:
	"""Vrátí barvu pro weather status"""
	var effects = get_weather_effect_on_building(building_type)
	
	if effects.is_empty():
		return "green"
	
	# Najdi nejhorší efekt
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

# ========== BUILDING MANAGEMENT HELPERS ==========

func get_all_buildings() -> Array:
	"""Vrátí seznam všech pozic budov"""
	if not building_system or not building_system.get("placed_buildings"):
		return []
	
	var building_positions = []
	var processed_buildings = {}  # Zabránit duplikátům
	
	for building_pos in building_system.placed_buildings:
		var building_data = building_system.placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		# Přidej jen jednou per building (protože multi-tile budovy jsou ve více keys)
		if building_id != -1 and not building_id in processed_buildings:
			building_positions.append(building_data.get("position", building_pos))
			processed_buildings[building_id] = true
	
	return building_positions

func destroy_building_at_position(position: Vector2):
	"""Zničí budovu na dané pozici"""
	if building_system and building_system.has_method("destroy_building_at_position"):
		var tile_pos = Vector2i(int(position.x), int(position.y))
		building_system.destroy_building_at_position(tile_pos)
		building_destroyed.emit(position.x * 1000 + position.y, 1.0)
		print("Building destroyed at: ", position)
	else:
		print("Cannot destroy building - BuildingSystem unavailable")

func damage_building_at_position(position: Vector2, damage_percent: float):
	"""Poškodí budovu na dané pozici"""
	if building_system and building_system.has_method("damage_building_at_position"):
		var tile_pos = Vector2i(int(position.x), int(position.y))
		building_system.damage_building_at_position(tile_pos, damage_percent)
		building_damaged.emit(position.x * 1000 + position.y, damage_percent)
		print("Building damaged at: ", position, " (", damage_percent * 100, "%)")
	else:
		print("Cannot damage building - BuildingSystem unavailable")

# ========== DISASTER EFFECTS (UPDATED) ==========

func apply_disaster_effects(weather: WeatherType, severity: DisasterSeverity):
	"""Aplikuje efekty katastrofy na budovy a zdroje"""
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
	"""Metanová bouře - poškození budov, bonus methane"""
	var damage_chance = get_damage_chance(severity)
	var building_count = damage_random_buildings(damage_chance, 0.1, 0.3)
	
	# Bonus methane ze storm
	var methane_bonus = 20.0 * get_severity_multiplier(severity)
	if safe_add_resource("METHANE", methane_bonus):
		print("Methane storm: +", methane_bonus, " methane, ", building_count, " buildings damaged")
	else:
		print("Methane storm: methane bonus failed, ", building_count, " buildings damaged")

func apply_ice_blizzard_effects(severity: DisasterSeverity):
	"""Ledová bouře - zvýšená spotřeba energie"""
	var energy_penalty = 3.0 * get_severity_multiplier(severity)
	
	if safe_add_consumption("ENERGY", energy_penalty):
		print("Ice blizzard: +", energy_penalty, " energy consumption")
		
		# Ulož efekt pro tracking
		active_weather_effects["ice_blizzard_consumption"] = {
			"type": "energy_consumption",
			"amount": energy_penalty,
			"start_time": get_current_time()
		}
		
		# Timer pro návrat na normál
		get_tree().create_timer(weather_duration).timeout.connect(
			func(): 
				safe_remove_consumption("ENERGY", energy_penalty)
				if "ice_blizzard_consumption" in active_weather_effects:
					active_weather_effects.erase("ice_blizzard_consumption")
				weather_effect_ended.emit("ice_blizzard_consumption")
		)
		
		weather_effect_started.emit("ice_blizzard_consumption", severity)
	else:
		print("Ice blizzard: energy consumption change failed")

func apply_titan_quake_effects(severity: DisasterSeverity):
	"""Zemětřesení - ničení budov"""
	var damage_chance = get_damage_chance(severity) * 1.5  # Vyšší šance na damage
	var building_count = damage_random_buildings(damage_chance, 0.2, 0.8)
	print("Titan quake: ", building_count, " buildings heavily damaged")

func apply_solar_flare_effects(severity: DisasterSeverity):
	"""Sluneční erupce - vypnutí elektroniky"""
	var energy_loss = 50.0 * get_severity_multiplier(severity)
	
	if safe_remove_resource("ENERGY", energy_loss):
		print("Solar flare: -", energy_loss, " energy lost")
	else:
		print("Solar flare: energy removal failed")

# ========== DAMAGE SYSTEM ==========

func get_damage_chance(severity: DisasterSeverity) -> float:
	match severity:
		DisasterSeverity.MINOR: return 0.1
		DisasterSeverity.MODERATE: return 0.25
		DisasterSeverity.SEVERE: return 0.4
		_: return 0.1

func get_severity_multiplier(severity: DisasterSeverity) -> float:
	match severity:
		DisasterSeverity.MINOR: return 1.0
		DisasterSeverity.MODERATE: return 1.5
		DisasterSeverity.SEVERE: return 2.5
		_: return 1.0

func damage_random_buildings(chance: float, min_damage: float, max_damage: float) -> int:
	"""Poškodí náhodné budovy"""
	var damaged_count = 0
	
	if not building_system:
		print("BuildingSystem není dostupný")
		return 0
	
	# Získej seznam všech budov
	var building_positions = get_all_buildings()
	
	if building_positions.size() == 0:
		print("Žádné budovy k poškození")
		return 0
	
	print("Kontroluji damage pro ", building_positions.size(), " budov")
	
	for building_pos in building_positions:
		if randf() < chance:
			var damage = randf_range(min_damage, max_damage)
			
			if damage > 0.5:  # 50%+ damage = destroy
				destroy_building_at_position(building_pos)
				damaged_count += 1
			else:
				damage_building_at_position(building_pos, damage)
				damaged_count += 1
	
	return damaged_count

# ========== PUBLIC API ==========

func get_current_weather() -> WeatherType:
	"""Vrátí aktuální počasí"""
	return current_weather

func get_weather_remaining_time() -> float:
	"""Vrátí zbývající čas aktuálního počasí"""
	return weather_duration

func force_weather(weather: WeatherType, severity: DisasterSeverity = DisasterSeverity.MINOR):
	"""Vynuceně nastaví počasí (pro debugging/cheaty)"""
	change_weather(weather, severity)

func is_weather_active() -> bool:
	"""Kontroluje, zda je aktivní nějaká katastrofa"""
	return current_weather != WeatherType.CLEAR and weather_duration > 0

# Debugging funkce pro UI
func get_current_severity() -> DisasterSeverity:
	"""Vrátí aktuální severity (pro debugging)"""
	return DisasterSeverity.MINOR  # Můžete rozšířit o sledování severity

# Rychlé spouštění katastrof pro testování
func debug_trigger_methane_storm():
	force_weather(WeatherType.METHANE_STORM, DisasterSeverity.MODERATE)

func debug_trigger_ice_blizzard():
	force_weather(WeatherType.ICE_BLIZZARD, DisasterSeverity.MODERATE)

func debug_trigger_titan_quake():
	force_weather(WeatherType.TITAN_QUAKE, DisasterSeverity.SEVERE)

func debug_trigger_solar_flare():
	force_weather(WeatherType.SOLAR_FLARE, DisasterSeverity.MODERATE)
