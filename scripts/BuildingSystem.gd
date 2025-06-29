# === TITAN QUEST - ENHANCED VERSION ===
# BuildingSystem.gd - Systém pro umístění budov s variantami a opravami

extends Node2D

# Typy budov - rozšířeno
enum BuildingType {
	HABITAT,
	POWER_GENERATOR_BASIC,
	POWER_GENERATOR_ADVANCED,
	FARM_BASIC,
	FARM_ADVANCED,
	WATER_EXTRACTOR_BASIC,
	WATER_EXTRACTOR_ADVANCED,
	METHANE_PROCESSOR_BASIC,
	METHANE_PROCESSOR_ADVANCED,
	DRILLING_TOWER_BASIC,
	DRILLING_TOWER_ADVANCED,
	VESSEL
}

# Signály pro game events
signal building_repaired(building_type: BuildingType, position: Vector2i)
signal victory_condition_met()

# Definice budov - kompletně přepracované
var building_definitions = {
	BuildingType.HABITAT: {
		"name": "Habitat",
		"size": Vector2i(3, 3),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 50,
			ResourceManager.ResourceType.ENERGY: 100,
			ResourceManager.ResourceType.WATER: 20,
			ResourceManager.ResourceType.OXYGEN: 30
		},
		"production": {
			ResourceManager.ResourceType.OXYGEN: 1.0
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 2.0,
			ResourceManager.ResourceType.FOOD: 1.5,
			ResourceManager.ResourceType.WATER: 1.0
		},
		"durability": 1.0,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 10,
			ResourceManager.ResourceType.ENERGY: 20
		},
		"placement_restriction": "any"
	},
	
	# POWER GENERATORS
	BuildingType.POWER_GENERATOR_BASIC: {
		"name": "Basic Power Generator",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 15,
			ResourceManager.ResourceType.METHANE: 10
		},
		"production": {
			ResourceManager.ResourceType.ENERGY: 3.0
		},
		"consumption": {
			ResourceManager.ResourceType.METHANE: 1.2
		},
		"durability": 0.6,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 5,
			ResourceManager.ResourceType.ENERGY: 10
		},
		"placement_restriction": "any"
	},
	BuildingType.POWER_GENERATOR_ADVANCED: {
		"name": "Advanced Power Generator",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 35,
			ResourceManager.ResourceType.METHANE: 25,
			ResourceManager.ResourceType.ENERGY: 15
		},
		"production": {
			ResourceManager.ResourceType.ENERGY: 6.0
		},
		"consumption": {
			ResourceManager.ResourceType.METHANE: 1.0
		},
		"durability": 0.9,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 8,
			ResourceManager.ResourceType.ENERGY: 15
		},
		"placement_restriction": "any"
	},
	
	# FARMS
	BuildingType.FARM_BASIC: {
		"name": "Basic Farm",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 12,
			ResourceManager.ResourceType.WATER: 5
		},
		"production": {
			ResourceManager.ResourceType.FOOD: 1.5,
			ResourceManager.ResourceType.OXYGEN: 0.3
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 2.0,
			ResourceManager.ResourceType.WATER: 1.2
		},
		"durability": 0.5,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 4,
			ResourceManager.ResourceType.ENERGY: 8
		},
		"placement_restriction": "any"
	},
	BuildingType.FARM_ADVANCED: {
		"name": "Advanced Farm",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 28,
			ResourceManager.ResourceType.WATER: 15,
			ResourceManager.ResourceType.ENERGY: 10
		},
		"production": {
			ResourceManager.ResourceType.FOOD: 3.5,
			ResourceManager.ResourceType.OXYGEN: 0.8
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 1.8,
			ResourceManager.ResourceType.WATER: 1.0
		},
		"durability": 0.8,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 7,
			ResourceManager.ResourceType.ENERGY: 12
		},
		"placement_restriction": "any"
	},
	
	# WATER EXTRACTORS
	BuildingType.WATER_EXTRACTOR_BASIC: {
		"name": "Basic Water Extractor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 20,
			ResourceManager.ResourceType.ENERGY: 30
		},
		"production": {
			ResourceManager.ResourceType.WATER: 2.5
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 3.5
		},
		"durability": 0.6,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 6,
			ResourceManager.ResourceType.ENERGY: 12
		},
		"placement_restriction": "any"
	},
	BuildingType.WATER_EXTRACTOR_ADVANCED: {
		"name": "Advanced Water Extractor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 45,
			ResourceManager.ResourceType.ENERGY: 60,
			ResourceManager.ResourceType.METHANE: 15
		},
		"production": {
			ResourceManager.ResourceType.WATER: 5.0
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 3.0
		},
		"durability": 0.85,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 10,
			ResourceManager.ResourceType.ENERGY: 18
		},
		"placement_restriction": "any"
	},
	
	# METHANE PROCESSORS
	BuildingType.METHANE_PROCESSOR_BASIC: {
		"name": "Basic Methane Processor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 18
		},
		"production": {
			ResourceManager.ResourceType.METHANE: 3.0
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 2.0
		},
		"durability": 0.5,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 5,
			ResourceManager.ResourceType.ENERGY: 10
		},
		"placement_restriction": "near_methane"
	},
	BuildingType.METHANE_PROCESSOR_ADVANCED: {
		"name": "Advanced Methane Processor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 40,
			ResourceManager.ResourceType.ENERGY: 25
		},
		"production": {
			ResourceManager.ResourceType.METHANE: 6.5
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 1.5
		},
		"durability": 0.8,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 8,
			ResourceManager.ResourceType.ENERGY: 15
		},
		"placement_restriction": "near_methane"
	},
	
	# DRILLING TOWERS
	BuildingType.DRILLING_TOWER_BASIC: {
		"name": "Basic Drilling Tower",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 25,
			ResourceManager.ResourceType.ENERGY: 40
		},
		"production": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 1.5
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 4.0
		},
		"durability": 0.4,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 8,
			ResourceManager.ResourceType.ENERGY: 15
		},
		"placement_restriction": "near_mountains"
	},
	BuildingType.DRILLING_TOWER_ADVANCED: {
		"name": "Advanced Drilling Tower",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 55,
			ResourceManager.ResourceType.ENERGY: 80,
			ResourceManager.ResourceType.METHANE: 20
		},
		"production": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 3.5
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 3.5
		},
		"durability": 0.7,
		"repair_cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 12,
			ResourceManager.ResourceType.ENERGY: 20
		},
		"placement_restriction": "near_mountains"
	},
	
	# VESSEL
	BuildingType.VESSEL: {
		"name": "Escape Vessel",
		"size": Vector2i(2, 3),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 1000,
			ResourceManager.ResourceType.ENERGY: 1000,
			ResourceManager.ResourceType.FOOD: 1000,
			ResourceManager.ResourceType.WATER: 1000,
			ResourceManager.ResourceType.METHANE: 1000,
			ResourceManager.ResourceType.OXYGEN: 1000
		},
		"production": {},
		"consumption": {},
		"durability": 1.0,
		"repair_cost": {},
		"placement_restriction": "methane_sea_only"
	}
}

# Umístěné budovy
var placed_buildings = {}

# Reference
@onready var resource_manager: Node = get_node("/root/ResourceManager")
@onready var map_generator: Node2D = get_parent()
@onready var tilemap: TileMap = get_parent().get_node("TileMap")

# Building mode - s tichým sledováním
var _is_building_mode = false
var is_building_mode: bool:
	get:
		return _is_building_mode
	set(value):
		_is_building_mode = value

var _is_repair_mode = false  
var is_repair_mode: bool:
	get:
		return _is_repair_mode
	set(value):
		_is_repair_mode = value

var selected_building_type = BuildingType.HABITAT
var building_preview_tiles = []

# Preview in building mode
var preview_sprite: Sprite2D = null
var preview_outline: Array[ColorRect] = []

var building_sprites = []
var building_textures = {}

# Repair mode je nyní definovaný výše s debug sledováním

func _ready():
	print("Enhanced BuildingSystem initialized")
	load_building_textures()

func load_building_textures():
	"""Načte textury pro všechny budovy včetně variant"""
#	print("Loading enhanced building textures...")
	
	var texture_paths = {
		BuildingType.HABITAT: "res://assets/buildings/habitat.png",
		BuildingType.POWER_GENERATOR_BASIC: "res://assets/buildings/power_generator_basic.png",
		BuildingType.POWER_GENERATOR_ADVANCED: "res://assets/buildings/power_generator_advanced.png",
		BuildingType.FARM_BASIC: "res://assets/buildings/farm_basic.png",
		BuildingType.FARM_ADVANCED: "res://assets/buildings/farm_advanced.png",
		BuildingType.WATER_EXTRACTOR_BASIC: "res://assets/buildings/water_extractor_basic.png",
		BuildingType.WATER_EXTRACTOR_ADVANCED: "res://assets/buildings/water_extractor_advanced.png",
		BuildingType.METHANE_PROCESSOR_BASIC: "res://assets/buildings/methane_processor_basic.png",
		BuildingType.METHANE_PROCESSOR_ADVANCED: "res://assets/buildings/methane_processor_advanced.png",
		BuildingType.DRILLING_TOWER_BASIC: "res://assets/buildings/drilling_tower_basic.png",
		BuildingType.DRILLING_TOWER_ADVANCED: "res://assets/buildings/drilling_tower_advanced.png",
		BuildingType.VESSEL: "res://assets/buildings/vessel.png"
	}
	
	var loaded_count = 0
	for building_type in texture_paths:
		var path = texture_paths[building_type]
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				building_textures[building_type] = texture
				loaded_count += 1
#				print("✅ Loaded texture: ", path)
			else:
				print("❌ Failed to load texture: ", path)
		else:
			print("⚠️ Texture not found: ", path)
	
	print("Building textures loaded: ", loaded_count, "/", texture_paths.size())
	
	if loaded_count == 0:
		print("⚠️ No textures loaded - all buildings will use colored placeholders")
	
	# Debug info
	#print("Available textures:")
	#for building_type in building_textures:
		#print("  - ", building_definitions[building_type]["name"])

# Reset flag - pro ochranu před aktivací během resetu
var _is_resetting = false

func enter_building_mode(building_type: BuildingType):
	"""Vstoupí do building módu"""
	# OCHRANA: Ignoruj volání během resetu
	if _is_resetting:
		return
	
	is_building_mode = true
	is_repair_mode = false
	selected_building_type = building_type

func enter_repair_mode():
	"""Vstoupí do repair módu"""
	# OCHRANA: Ignoruj volání během resetu
	if _is_resetting:
		return
		
	is_repair_mode = true
	is_building_mode = false

func exit_building_mode():
	"""Opustí building/repair mód"""
	is_building_mode = false
	is_repair_mode = false
	clear_building_preview()
	print("Exited building/repair mode")

func force_exit_all_modes():
	"""Force vypne všechny módy - pro reset"""
	print("=== FORCE EXITING ALL MODES ===")
	
	# Explicitně vypni všechny módy
	is_building_mode = false
	is_repair_mode = false
	
	# Vyčisti všechny preview
	clear_building_preview()
	
	# Reset selected type
	selected_building_type = BuildingType.HABITAT
	
	# Clear any potential preview arrays
	building_preview_tiles.clear()
	
	print("All modes force exited: building=", is_building_mode, ", repair=", is_repair_mode)

func _input(event):
	"""Input handling pro building system"""
	if not is_building_mode and not is_repair_mode:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
			
			if is_repair_mode:
				attempt_repair_building(tile_pos)
			else:
				attempt_place_building(tile_pos)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			exit_building_mode()
	
	elif event is InputEventMouseMotion and is_building_mode:
		update_building_preview()

func attempt_place_building(tile_pos: Vector2i) -> bool:
	"""Pokusí se umístit budovu na danou pozici"""
	var building_def = building_definitions[selected_building_type]
	
	print("=== ATTEMPTING TO PLACE BUILDING ===")
	print("Building type: ", building_def["name"])
	print("Position: ", tile_pos)
	
	# Zkontroluj placement restrictions
	if not check_placement_restriction(tile_pos, building_def):
		print("❌ Placement restriction failed!")
		return false
	
	# Zkontroluj validitu pozice
	if not is_valid_building_position(tile_pos, building_def["size"]):
		print("❌ Invalid building position!")
		return false
	
	# Zkontroluj zdroje
	if not resource_manager.can_afford(building_def["cost"]):
		print("❌ Not enough resources!")
		return false
	
	clear_building_preview()
	place_building(tile_pos, selected_building_type)
	
	# Zkontroluj vítěznou podmínku
	if selected_building_type == BuildingType.VESSEL:
		victory_condition_met.emit()
		print("🎉 VICTORY! Escape vessel built!")
	
	is_building_mode = false
	return true

func attempt_repair_building(tile_pos: Vector2i) -> bool:
	"""Pokusí se opravit budovu na pozici"""
	if not tile_pos in placed_buildings:
		print("No building to repair at: ", tile_pos)
		return false
	
	var building_data = placed_buildings[tile_pos]
	var building_type = building_data.get("type", -1)
	var building_def = building_definitions[building_type]
	var current_damage = building_data.get("damage", 0.0)
	
	if current_damage <= 0.0:
		print("Building is not damaged")
		return false
	
	# Zkontroluj repair costs
	var repair_cost = building_def.get("repair_cost", {})
	if not resource_manager.can_afford(repair_cost):
		print("❌ Not enough resources for repair!")
		return false
	
	# Proveď opravu
	resource_manager.spend_resources(repair_cost)
	repair_building_at_position(tile_pos, 1.0)  # Plná oprava
	building_repaired.emit(building_type, tile_pos)
	
	print("✅ Building repaired successfully!")
	return true

func check_placement_restriction(tile_pos: Vector2i, building_def: Dictionary) -> bool:
	"""Kontroluje speciální omezení umístění budovy"""
	var restriction = building_def.get("placement_restriction", "any")
	
	match restriction:
		"any":
			return true
		"near_methane":
			return is_near_methane_source(tile_pos, building_def["size"])
		"near_mountains":
			return is_near_mountains(tile_pos, building_def["size"])
		"methane_sea_only":
			return is_on_methane_sea(tile_pos, building_def["size"])
		_:
			return true

func is_near_methane_source(tile_pos: Vector2i, size: Vector2i) -> bool:
	"""Kontroluje zda je budova blízko methane jezera nebo moře"""
	var search_radius = 1
	
	for x in range(tile_pos.x - search_radius, tile_pos.x + size.x + search_radius):
		for y in range(tile_pos.y - search_radius, tile_pos.y + size.y + search_radius):
			if x >= 0 and y >= 0 and x < map_generator.MAP_WIDTH and y < map_generator.MAP_HEIGHT:
				var terrain_type = map_generator.terrain_grid[x][y]
				if terrain_type == map_generator.TerrainType.METHANE_LAKE or \
				   terrain_type == map_generator.TerrainType.METHANE_SEA:
					return true
	
	print("Methane processor must be built near methane lake or sea")
	return false

func is_near_mountains(tile_pos: Vector2i, size: Vector2i) -> bool:
	"""Kontroluje zda je drilling tower blízko hor"""
	var search_radius = 1
	
	for x in range(tile_pos.x - search_radius, tile_pos.x + size.x + search_radius):
		for y in range(tile_pos.y - search_radius, tile_pos.y + size.y + search_radius):
			if x >= 0 and y >= 0 and x < map_generator.MAP_WIDTH and y < map_generator.MAP_HEIGHT:
				var terrain_type = map_generator.terrain_grid[x][y]
				if terrain_type == map_generator.TerrainType.ICE_MOUNTAINS:
					return true
	
	print("Drilling tower must be built near ice mountains")
	return false

func is_on_methane_sea(tile_pos: Vector2i, size: Vector2i) -> bool:
	"""Kontroluje zda je celá budova na methane moři"""
	for x in range(tile_pos.x, tile_pos.x + size.x):
		for y in range(tile_pos.y, tile_pos.y + size.y):
			if x < 0 or y < 0 or x >= map_generator.MAP_WIDTH or y >= map_generator.MAP_HEIGHT:
				return false
			
			var terrain_type = map_generator.terrain_grid[x][y]
			if terrain_type != map_generator.TerrainType.METHANE_SEA:
				# print("Vessel must be built entirely on methane sea")
				return false
	
	return true

func is_valid_building_position(tile_pos: Vector2i, size: Vector2i) -> bool:
	"""Zkontroluje zda je pozice validní pro budovu"""
	# Zkontroluj hranice mapy
	if tile_pos.x < 0 or tile_pos.y < 0:
		return false
	if tile_pos.x + size.x > map_generator.MAP_WIDTH:
		return false
	if tile_pos.y + size.y > map_generator.MAP_HEIGHT:
		return false
	
	# Pro vessel kontrolujeme pouze kolize s budovami (ne terén)
	if selected_building_type == BuildingType.VESSEL:
		for x in range(tile_pos.x, tile_pos.x + size.x):
			for y in range(tile_pos.y, tile_pos.y + size.y):
				var key = Vector2i(x, y)
				if key in placed_buildings:
					return false
		return true
	
	# Pro ostatní budovy kontroluj terén
	for x in range(tile_pos.x, tile_pos.x + size.x):
		for y in range(tile_pos.y, tile_pos.y + size.y):
			var terrain_type = map_generator.terrain_grid[x][y]
			
			# Nelze stavět na vodě/jezeře (kromě vessel)
			if terrain_type == map_generator.TerrainType.METHANE_SEA:
				return false
			if terrain_type == map_generator.TerrainType.METHANE_LAKE:
				return false
			
			# Zkontroluj kolize s existujícími budovami
			var key = Vector2i(x, y)
			if key in placed_buildings:
				return false
	
	return true

func calculate_weather_damage_modifier(building_type: BuildingType) -> float:
	"""Vypočítá modifikátor poškození podle odolnosti budovy"""
	var building_def = building_definitions[building_type]
	var durability = building_def.get("durability", 1.0)
	
	# Čím nižší durability, tím vyšší šance na poškození
	return 2.0 - durability

func place_building(tile_pos: Vector2i, building_type: BuildingType):
	"""Umístí budovu na mapu"""
	var building_def = building_definitions[building_type]
	
	# Utratí zdroje
	resource_manager.spend_resources(building_def["cost"])
	
	# Zaregistruj budovu
	var building_id = placed_buildings.size()
	var building_data = {
		"id": building_id,
		"type": building_type,
		"position": tile_pos,
		"size": building_def["size"],
		"damage": 0.0,
		"durability": building_def.get("durability", 1.0)
	}
	
	# Označ tiles jako obsazené
	for x in range(tile_pos.x, tile_pos.x + building_def["size"].x):
		for y in range(tile_pos.y, tile_pos.y + building_def["size"].y):
			var key = Vector2i(x, y)
			placed_buildings[key] = building_data
	
	# Přidej production/consumption
	for resource_type in building_def["production"]:
		resource_manager.add_production(resource_type, building_def["production"][resource_type])
	
	for resource_type in building_def["consumption"]:
		resource_manager.add_consumption(resource_type, building_def["consumption"][resource_type])
	
	print("Built ", building_def["name"], " at ", tile_pos)
	
	# Vykresli budovu
	render_building_sprite(tile_pos, building_def["size"], building_type)

func render_building_sprite(tile_pos: Vector2i, size: Vector2i, building_type: BuildingType):
	"""Vykreslí sprite budovy"""
	var building_sprite = Sprite2D.new()
	
	# Nastav texturu - s fallback na placeholder
	if building_type in building_textures:
		building_sprite.texture = building_textures[building_type]
		print("Using texture for: ", building_definitions[building_type]["name"])
	else:
		print("No texture found for: ", building_definitions[building_type]["name"], " - using placeholder")
		create_placeholder_sprite(building_sprite, size)
	
	# Pozice a scale
	var world_pos = Vector2(
		(tile_pos.x + size.x / 2.0) * 64,
		(tile_pos.y + size.y / 2.0) * 64
	)
	building_sprite.position = world_pos
	
	if building_sprite.texture:
		var scale_factor = Vector2(
			size.x * 64.0 / building_sprite.texture.get_width(),
			size.y * 64.0 / building_sprite.texture.get_height()
		)
		building_sprite.scale = scale_factor
		print("Building sprite scale: ", scale_factor)
	
	# Přidej do scény
	get_parent().add_child(building_sprite)
	building_sprites.append(building_sprite)
	
	# Ulož referenci
	var building_data = placed_buildings[Vector2i(tile_pos.x, tile_pos.y)]
	if building_data:
		building_data["sprite"] = building_sprite
	
	print("Building sprite rendered at: ", world_pos)

func create_placeholder_sprite(sprite: Sprite2D, size: Vector2i):
	"""Vytvoří placeholder texturu s barevným rozlišením"""
	var image = Image.create(64 * size.x, 64 * size.y, false, Image.FORMAT_RGB8)
	
	# Různé barvy pro různé typy budov
	var color = Color.MAGENTA  # Default
	if selected_building_type == BuildingType.HABITAT:
		color = Color.GREEN
	elif str(selected_building_type).contains("POWER_GENERATOR"):
		color = Color.YELLOW
	elif str(selected_building_type).contains("FARM"):
		color = Color.LIME
	elif str(selected_building_type).contains("WATER_EXTRACTOR"):
		color = Color.CYAN
	elif str(selected_building_type).contains("METHANE_PROCESSOR"):
		color = Color.ORANGE
	elif str(selected_building_type).contains("DRILLING_TOWER"):
		color = Color.GRAY
	elif selected_building_type == BuildingType.VESSEL:
		color = Color.GOLD
	
	image.fill(color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	print("Created placeholder texture with color: ", color)

func update_building_preview():
	"""Aktualizuje náhled budovy při pohybu myši"""
	if not is_building_mode:
		return
	
	clear_building_preview()
	
	var mouse_pos = get_global_mouse_position()
	var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
	var building_def = building_definitions[selected_building_type]
	
	# Zkontroluj všechny podmínky
	var position_valid = is_valid_building_position(tile_pos, building_def["size"])
	var placement_valid = check_placement_restriction(tile_pos, building_def)
	var resources_available = resource_manager.can_afford(building_def["cost"])
	
	var is_valid = position_valid and placement_valid and resources_available
	
	# Vytvoř preview
	create_preview_sprite(tile_pos, building_def["size"], is_valid)
	create_preview_outline_clean(tile_pos, building_def["size"], is_valid)

func create_preview_sprite(tile_pos: Vector2i, size: Vector2i, is_valid: bool):
	"""Vytvoří semi-transparentní preview sprite budovy"""
	if not selected_building_type in building_textures:
		return
	
	preview_sprite = Sprite2D.new()
	preview_sprite.texture = building_textures[selected_building_type]
	
	var world_pos = Vector2(
		(tile_pos.x + size.x / 2.0) * 64,
		(tile_pos.y + size.y / 2.0) * 64
	)
	preview_sprite.position = world_pos
	
	if preview_sprite.texture:
		var scale_factor = Vector2(
			size.x * 64.0 / preview_sprite.texture.get_width(),
			size.y * 64.0 / preview_sprite.texture.get_height()
		)
		preview_sprite.scale = scale_factor
	
	# Barevné rozlišení podle validity
	if is_valid:
		preview_sprite.modulate = Color(0.8, 1.0, 0.8, 0.7)
	else:
		preview_sprite.modulate = Color(1.0, 0.6, 0.6, 0.7)
	
	get_parent().add_child(preview_sprite)

func create_preview_outline_clean(tile_pos: Vector2i, size: Vector2i, is_valid: bool):
	"""Vytvoří čistý obrys budovy"""
	var outline_color = Color.GREEN if is_valid else Color.RED
	var outline_thickness = 4
	
	var total_width = size.x * 64
	var total_height = size.y * 64
	var start_pos = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	
	# 4 okraje outline
	var outlines = [
		{pos = start_pos - Vector2(outline_thickness, outline_thickness), 
		 size = Vector2(total_width + 2 * outline_thickness, outline_thickness)},
		{pos = Vector2(start_pos.x - outline_thickness, start_pos.y + total_height), 
		 size = Vector2(total_width + 2 * outline_thickness, outline_thickness)},
		{pos = start_pos - Vector2(outline_thickness, outline_thickness), 
		 size = Vector2(outline_thickness, total_height + 2 * outline_thickness)},
		{pos = Vector2(start_pos.x + total_width, start_pos.y - outline_thickness), 
		 size = Vector2(outline_thickness, total_height + 2 * outline_thickness)}
	]
	
	for outline_data in outlines:
		var outline = ColorRect.new()
		outline.color = outline_color
		outline.position = outline_data.pos
		outline.size = outline_data.size
		get_parent().add_child(outline)
		preview_outline.append(outline)

func clear_building_preview():
	"""Vyčistí náhled budovy"""
	if preview_sprite:
		preview_sprite.queue_free()
		preview_sprite = null
	
	for outline_element in preview_outline:
		if outline_element:
			outline_element.queue_free()
	preview_outline.clear()

# REPAIR SYSTEM
func repair_building_at_position(tile_pos: Vector2i, repair_amount: float = 1.0):
	"""Opraví budovu na pozici"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		# var building_type = building_data.get("type", -1)
		# var building_def = building_definitions[building_type]
		
		if "damage" in building_data and building_data["damage"] > 0.0:
			# Oprav damage
			var old_damage = building_data["damage"]
			building_data["damage"] = max(0.0, building_data["damage"] - repair_amount)
			
			# Obnov vizuální stav
			if "sprite" in building_data and building_data["sprite"]:
				var sprite = building_data["sprite"]
				if building_data["damage"] <= 0.0:
					sprite.modulate = Color.WHITE  # Plně opraveno
				else:
					# Postupné zlepšování barvy
					var damage_ratio = building_data["damage"]
					if damage_ratio > 0.5:
						sprite.modulate = Color(1, 0.4, 0.4)
					elif damage_ratio > 0.25:
						sprite.modulate = Color(1, 0.7, 0.4)
					else:
						sprite.modulate = Color(1, 1, 0.6)
			
			print("Building repaired at: ", tile_pos)
			print("Damage reduced from %.1f%% to %.1f%%" % [old_damage * 100, building_data["damage"] * 100])

func damage_building_at_position(tile_pos: Vector2i, damage_percent: float):
	"""Poškodí budovu s ohledem na durability"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data.get("type", -1)
		var durability = building_data.get("durability", 1.0)
		
		# Aplikuj damage s modifikátorem durability
		var actual_damage = damage_percent * (2.0 - durability)
		building_data["damage"] = building_data.get("damage", 0.0) + actual_damage
		
		# Vizuální efekty podle úrovně damage
		if "sprite" in building_data and building_data["sprite"]:
			var sprite = building_data["sprite"]
			var total_damage = building_data["damage"]
			
			if total_damage > 0.75:
				sprite.modulate = Color(1, 0.2, 0.2)  # Velmi červené
			elif total_damage > 0.5:
				sprite.modulate = Color(1, 0.4, 0.4)  # Červené
			elif total_damage > 0.25:
				sprite.modulate = Color(1, 0.7, 0.4)  # Oranžové
			else:
				sprite.modulate = Color(1, 1, 0.6)    # Žluté
			
			# Bliknutí při damage
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.5, 0.1)
			tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		
		print("Building damaged: ", building_definitions[building_type]["name"])
		print("Damage: %.1f%% (durability modifier: %.1f)" % [actual_damage * 100, 2.0 - durability])
		
		# Automatické zničení při kritickém damage
		if building_data["damage"] >= 1.0:
			print("Building destroyed due to excessive damage")
			destroy_building_at_position(tile_pos)

func destroy_building_at_position(tile_pos: Vector2i):
	"""Zničí budovu"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data["type"]
		var building_def = building_definitions[building_type]
		
		print("=== DESTROYING BUILDING ===")
		print("Type: ", building_def["name"])
		print("Position: ", tile_pos)
		
		# Odeber production/consumption
		for resource_type in building_def["production"]:
			resource_manager.remove_production(resource_type, building_def["production"][resource_type])
		for resource_type in building_def["consumption"]:
			resource_manager.remove_consumption(resource_type, building_def["consumption"][resource_type])
		
		# Smaž sprite s animací
		if "sprite" in building_data and building_data["sprite"]:
			var sprite = building_data["sprite"]
			var tween = create_tween()
			tween.parallel().tween_property(sprite, "modulate", Color.RED, 0.2)
			tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.3)
			tween.tween_callback(sprite.queue_free)
		
		# Smaž ze všech tiles
		var size = building_def["size"]
		var start_pos = building_data["position"]
		for x in range(start_pos.x, start_pos.x + size.x):
			for y in range(start_pos.y, start_pos.y + size.y):
				var key = Vector2i(x, y)
				if key in placed_buildings:
					placed_buildings.erase(key)

# RESET SYSTEM - ENHANCED
func reset_buildings():
	"""Resetuje všechny budovy a režimy"""
	print("=== RESETTING ENHANCED BUILDINGS ===")
	
	# AKTIVUJ RESET FLAG - blokuje aktivaci building mode
	_is_resetting = true
	
	# NEJDŘÍV resetuj módy - předejde reactivaci
	print("Resetting building modes FIRST...")
	is_building_mode = false
	is_repair_mode = false
	selected_building_type = BuildingType.HABITAT
	
	# Vyčištění preview před mazáním sprites
	clear_building_preview()
	
	# Reset všech sprite objektů
	print("Clearing building sprites...")
	for sprite in building_sprites:
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	building_sprites.clear()
	
	# Reset umístěných budov - BEZ produkce/spotřeby removal!
	print("Clearing building data...")
	placed_buildings.clear()
	
	# Reset building preview arrays
	building_preview_tiles.clear()
	
	# Force garbage collection
	await get_tree().process_frame
	
	# DEAKTIVUJ RESET FLAG po krátkém čekání
	await get_tree().create_timer(0.1).timeout
	_is_resetting = false
	
	print("All enhanced buildings reset")
	print("Building modes reset: building_mode=", is_building_mode, ", repair_mode=", is_repair_mode)
	print("Selected building type: ", selected_building_type)

# UTILITY FUNCTIONS
func get_building_repair_cost(tile_pos: Vector2i) -> Dictionary:
	"""Vrátí náklady na opravu budovy"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data.get("type", -1)
		var building_def = building_definitions[building_type]
		return building_def.get("repair_cost", {})
	return {}

func get_building_damage_status(tile_pos: Vector2i) -> Dictionary:
	"""Vrátí status poškození budovy"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var damage = building_data.get("damage", 0.0)
		var durability = building_data.get("durability", 1.0)
		
		return {
			"damage_percent": damage * 100,
			"needs_repair": damage > 0.0,
			"durability": durability,
			"condition": get_condition_text(damage)
		}
	return {}

func get_condition_text(damage: float) -> String:
	"""Vrátí textový popis stavu budovy"""
	if damage <= 0.0:
		return "Excellent"
	elif damage <= 0.25:
		return "Good"
	elif damage <= 0.5:
		return "Fair"
	elif damage <= 0.75:
		return "Poor"
	else:
		return "Critical"

func can_repair_building(tile_pos: Vector2i) -> bool:
	"""Kontroluje zda lze budovu opravit"""
	if not tile_pos in placed_buildings:
		return false
	
	var building_data = placed_buildings[tile_pos]
	var damage = building_data.get("damage", 0.0)
	
	if damage <= 0.0:
		return false  # Není poškozená
	
	var building_type = building_data.get("type", -1)
	var building_def = building_definitions[building_type]
	var repair_cost = building_def.get("repair_cost", {})
	
	return resource_manager.can_afford(repair_cost)

func get_buildings_needing_repair() -> Array:
	"""Vrátí seznam budov potřebujících opravu"""
	var damaged_buildings = []
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			var damage = building_data.get("damage", 0.0)
			if damage > 0.0:
				damaged_buildings.append({
					"position": building_data.get("position", building_pos),
					"type": building_data.get("type", -1),
					"damage": damage,
					"name": building_definitions[building_data.get("type", -1)]["name"]
				})
			processed_buildings[building_id] = true
	
	return damaged_buildings

# ENHANCED BUILDING QUERIES
func get_building_variants(base_type: String) -> Array:
	"""Vrátí varianty budovy (basic/advanced)"""
	match base_type:
		"POWER_GENERATOR":
			return [BuildingType.POWER_GENERATOR_BASIC, BuildingType.POWER_GENERATOR_ADVANCED]
		"FARM":
			return [BuildingType.FARM_BASIC, BuildingType.FARM_ADVANCED]
		"WATER_EXTRACTOR":
			return [BuildingType.WATER_EXTRACTOR_BASIC, BuildingType.WATER_EXTRACTOR_ADVANCED]
		"METHANE_PROCESSOR":
			return [BuildingType.METHANE_PROCESSOR_BASIC, BuildingType.METHANE_PROCESSOR_ADVANCED]
		"DRILLING_TOWER":
			return [BuildingType.DRILLING_TOWER_BASIC, BuildingType.DRILLING_TOWER_ADVANCED]
		_:
			return []

func get_building_efficiency(tile_pos: Vector2i) -> float:
	"""Vypočítá efektivitu budovy na základě damage"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var damage = building_data.get("damage", 0.0)
		return max(0.1, 1.0 - damage * 0.8)  # 80% reduction při max damage
	return 1.0

func get_building_production_rate(tile_pos: Vector2i, resource_type) -> float:
	"""Vrátí aktuální produkční rychlost budovy s ohledem na damage"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data.get("type", -1)
		var building_def = building_definitions[building_type]
		
		if resource_type in building_def.get("production", {}):
			var base_production = building_def["production"][resource_type]
			var efficiency = get_building_efficiency(tile_pos)
			return base_production * efficiency
	return 0.0

func get_building_consumption_rate(tile_pos: Vector2i, resource_type) -> float:
	"""Vrátí aktuální spotřebu budovy s ohledem na damage"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data.get("type", -1)
		var building_def = building_definitions[building_type]
		
		if resource_type in building_def.get("consumption", {}):
			var base_consumption = building_def["consumption"][resource_type]
			# Consumption se nezvyšuje s damage - budova prostě méně produkuje
			return base_consumption
	return 0.0

func get_building_info(tile_pos: Vector2i) -> Dictionary:
	"""Vrátí kompletní informace o budově"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data.get("type", -1)
		var building_def = building_definitions[building_type]
		
		return {
			"name": building_def.get("name", "Unknown"),
			"type": building_type,
			"position": building_data.get("position", tile_pos),
			"size": building_def.get("size", Vector2i(1, 1)),
			"damage": building_data.get("damage", 0.0),
			"durability": building_data.get("durability", 1.0),
			"efficiency": get_building_efficiency(tile_pos),
			"condition": get_condition_text(building_data.get("damage", 0.0)),
			"can_repair": can_repair_building(tile_pos),
			"repair_cost": building_def.get("repair_cost", {}),
			"production": building_def.get("production", {}),
			"consumption": building_def.get("consumption", {}),
			"placement_restriction": building_def.get("placement_restriction", "any")
		}
	return {}

func get_buildings_by_type(building_type: BuildingType) -> Array:
	"""Vrátí všechny budovy daného typu"""
	var buildings_of_type = []
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			if building_data.get("type", -1) == building_type:
				buildings_of_type.append({
					"position": building_data.get("position", building_pos),
					"data": building_data
				})
			processed_buildings[building_id] = true
	
	return buildings_of_type

func get_total_production(resource_type) -> float:
	"""Vypočítá celkovou produkci daného zdroje ze všech budov"""
	var total = 0.0
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			var building_type = building_data.get("type", -1)
			var building_def = building_definitions[building_type]
			
			if resource_type in building_def.get("production", {}):
				var base_production = building_def["production"][resource_type]
				var efficiency = get_building_efficiency(building_data.get("position", building_pos))
				total += base_production * efficiency
			
			processed_buildings[building_id] = true
	
	return total

func get_total_consumption(resource_type) -> float:
	"""Vypočítá celkovou spotřebu daného zdroje ze všech budov"""
	var total = 0.0
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			var building_type = building_data.get("type", -1)
			var building_def = building_definitions[building_type]
			
			if resource_type in building_def.get("consumption", {}):
				total += building_def["consumption"][resource_type]
			
			processed_buildings[building_id] = true
	
	return total

# EXISTING FUNCTIONS (kept for compatibility)
func get_all_buildings() -> Array:
	var building_positions = []
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			building_positions.append(building_data.get("position", building_pos))
			processed_buildings[building_id] = true
	
	return building_positions

func is_building_at_position(tile_pos: Vector2i) -> bool:
	return tile_pos in placed_buildings

func get_building_at_position(tile_pos: Vector2i) -> Dictionary:
	if tile_pos in placed_buildings:
		return placed_buildings[tile_pos]
	return {}

# DEBUG AND TESTING FUNCTIONS
func debug_test_placement_restrictions():
	"""Debug funkce pro testování placement restrictions"""
	print("=== TESTING PLACEMENT RESTRICTIONS ===")
	
	# Test methane processor near methane
	var test_pos = Vector2i(10, 10)
	print("Testing methane processor at ", test_pos)
	var building_def = building_definitions[BuildingType.METHANE_PROCESSOR_BASIC]
	var result = check_placement_restriction(test_pos, building_def)
	print("Near methane result: ", result)
	
	# Test drilling tower near mountains
	print("Testing drilling tower at ", test_pos)
	building_def = building_definitions[BuildingType.DRILLING_TOWER_BASIC]
	result = check_placement_restriction(test_pos, building_def)
	print("Near ice mountains result: ", result)

func debug_force_place_building(building_type: BuildingType, tile_pos: Vector2i):
	"""Debug funkce pro vynucené umístění budovy"""
	print("=== FORCE PLACING BUILDING ===")
	print("Type: ", building_definitions[building_type]["name"])
	print("Position: ", tile_pos)
	
	selected_building_type = building_type
	place_building(tile_pos, building_type)
	
	print("Building force-placed successfully")

# DEBUG FUNCTIONS
func debug_damage_all_buildings(damage_percent: float):
	for building_pos in get_all_buildings():
		damage_building_at_position(Vector2i(building_pos.x, building_pos.y), damage_percent)

func debug_repair_all_buildings():
	for building_pos in get_all_buildings():
		repair_building_at_position(Vector2i(building_pos.x, building_pos.y), 1.0)

func debug_print_building_info():
	print("=== BUILDING SYSTEM STATUS ===")
	print("Total buildings: ", get_all_buildings().size())
	print("Buildings needing repair: ", get_buildings_needing_repair().size())
	print("Building mode: ", is_building_mode)
	print("Repair mode: ", is_repair_mode)
	print("Selected building type: ", selected_building_type)
	print("Preview sprite exists: ", preview_sprite != null)
	print("Preview outline count: ", preview_outline.size())
	print("Building sprites count: ", building_sprites.size())
	print("Placed buildings count: ", placed_buildings.size())

func debug_force_disable_modes():
	"""Debug funkce pro vynucené vypnutí módů"""
	print("=== DEBUG FORCE DISABLE MODES ===")
	print("Before: building_mode=", is_building_mode, ", repair_mode=", is_repair_mode)
	
	force_exit_all_modes()
	
	print("After: building_mode=", is_building_mode, ", repair_mode=", is_repair_mode)
	print("Modes disabled successfully")
