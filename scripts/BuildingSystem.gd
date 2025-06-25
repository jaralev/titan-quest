# === TITAN QUEST - DAY 2 ===
# BuildingSystem.gd - Systém pro umístění budov
# OPRAVENÁ VERZE - extends Node2D místo Node

extends Node2D

# Typy budov
enum BuildingType {
	HABITAT,
	POWER_GENERATOR,
	FARM,
	WATER_EXTRACTOR,
	METHANE_PROCESSOR
}

# Definice budov
var building_definitions = {
	BuildingType.HABITAT: {
		"name": "Habitat",
		"size": Vector2i(3, 3),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 10,
			ResourceManager.ResourceType.ENERGY: 20
		},
		"production": {},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 1.0,
			ResourceManager.ResourceType.OXYGEN: 0.5
		}
	},
	BuildingType.POWER_GENERATOR: {
		"name": "Power Generator",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 15,
			ResourceManager.ResourceType.METHANE: 10
		},
		"production": {
			ResourceManager.ResourceType.ENERGY: 5.0
		},
		"consumption": {
			ResourceManager.ResourceType.METHANE: 1.0
		}
	},
	BuildingType.FARM: {
		"name": "Hydroponic Farm",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 12,
			ResourceManager.ResourceType.WATER: 5
		},
		"production": {
			ResourceManager.ResourceType.FOOD: 2.0,
			ResourceManager.ResourceType.OXYGEN: 0.5
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 2.0,
			ResourceManager.ResourceType.WATER: 1.0
		}
	},
	BuildingType.WATER_EXTRACTOR: {
		"name": "Water Extractor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 20,
			ResourceManager.ResourceType.ENERGY: 30
		},
		"production": {
			ResourceManager.ResourceType.WATER: 3.0
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 3.0
		}
	},
	BuildingType.METHANE_PROCESSOR: {
		"name": "Methane Processor",
		"size": Vector2i(2, 2),
		"cost": {
			ResourceManager.ResourceType.BUILDING_MATERIALS: 18
		},
		"production": {
			ResourceManager.ResourceType.METHANE: 4.0
		},
		"consumption": {
			ResourceManager.ResourceType.ENERGY: 1.5
		}
	}
}

# Umístěné budovy
var placed_buildings = {}

# Reference
@onready var resource_manager: Node = get_node("/root/ResourceManager")
@onready var map_generator: Node2D = get_parent()
@onready var tilemap: TileMap = get_parent().get_node("TileMap")

# Building mode
var is_building_mode = false
var selected_building_type = BuildingType.HABITAT
var building_preview_tiles = []

# Preview in building mode
var preview_sprite: Sprite2D = null
var preview_outline: Array[ColorRect] = []

var building_sprites = []
var building_textures = {}

func _ready():
	print("BuildingSystem initialized")
	load_building_textures()

func load_building_textures():
	"""Načte textury dynamicky"""
	print("Loading building textures dynamically...")
	
	var texture_paths = {
		BuildingType.HABITAT: "res://assets/buildings/habitat.png",
		BuildingType.POWER_GENERATOR: "res://assets/buildings/power-generator.png", 
		BuildingType.FARM: "res://assets/buildings/farm.png",
		BuildingType.WATER_EXTRACTOR: "res://assets/buildings/water_extractor.png",
		BuildingType.METHANE_PROCESSOR: "res://assets/buildings/methane_processor.png"
	}
	
	for building_type in texture_paths:
		var path = texture_paths[building_type]
		if ResourceLoader.exists(path):
			var texture = load(path)
			building_textures[building_type] = texture
			print("Loaded texture: ", path)
		else:
			print("Warning: Texture not found: ", path)
	
	print("Building textures loaded: ", building_textures.size(), "/5")

func enter_building_mode(building_type: BuildingType):
	"""Vstoupí do building módu"""
	is_building_mode = true
	selected_building_type = building_type
	print("Entered building mode: ", building_definitions[building_type]["name"])

func exit_building_mode():
	"""Opustí building mód"""
	is_building_mode = false
	clear_building_preview()  # Vyčisti preview při odchodu
	print("Exited building mode")

func create_preview_outline_clean(tile_pos: Vector2i, size: Vector2i, is_valid: bool):
	"""Vytvoří čistý obrys pouze po vnějším obvodu budovy"""
	var outline_color = Color.GREEN if is_valid else Color.RED
	var outline_thickness = 4
	
	# Celková velikost budovy v pixelech
	var total_width = size.x * 64
	var total_height = size.y * 64
	var start_pos = Vector2(tile_pos.x * 64, tile_pos.y * 64)
	
	# Horní okraj
	var top_line = ColorRect.new()
	top_line.color = outline_color
	top_line.position = start_pos - Vector2(outline_thickness, outline_thickness)
	top_line.size = Vector2(total_width + 2 * outline_thickness, outline_thickness)
	get_parent().add_child(top_line)
	preview_outline.append(top_line)
	
	# Dolní okraj
	var bottom_line = ColorRect.new()
	bottom_line.color = outline_color
	bottom_line.position = Vector2(start_pos.x - outline_thickness, start_pos.y + total_height)
	bottom_line.size = Vector2(total_width + 2 * outline_thickness, outline_thickness)
	get_parent().add_child(bottom_line)
	preview_outline.append(bottom_line)
	
	# Levý okraj
	var left_line = ColorRect.new()
	left_line.color = outline_color
	left_line.position = start_pos - Vector2(outline_thickness, outline_thickness)
	left_line.size = Vector2(outline_thickness, total_height + 2 * outline_thickness)
	get_parent().add_child(left_line)
	preview_outline.append(left_line)
	
	# Pravý okraj
	var right_line = ColorRect.new()
	right_line.color = outline_color
	right_line.position = Vector2(start_pos.x + total_width, start_pos.y - outline_thickness)
	right_line.size = Vector2(outline_thickness, total_height + 2 * outline_thickness)
	get_parent().add_child(right_line)
	preview_outline.append(right_line)

func _input(event):
	"""Input handling pro building system"""
	if not is_building_mode:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
			attempt_place_building(tile_pos)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			exit_building_mode()
	
	elif event is InputEventMouseMotion:
		update_building_preview()

func attempt_place_building(tile_pos: Vector2i) -> bool:
	"""Pokusí se umístit budovu na danou pozici"""
	var building_def = building_definitions[selected_building_type]
	
	print("=== ATTEMPTING TO PLACE BUILDING ===")
	print("Building type: ", building_def["name"])
	print("Position: ", tile_pos)
	
	# Zkontroluj validitu pozice
	if not is_valid_building_position(tile_pos, building_def["size"]):
		print("❌ Invalid building position!")
		print("Reason: Cannot build on water, mountains, or occupied tiles")
		return false
	else:
		print("✅ Position is valid")
	
	# Detailní kontrola zdrojů
	print("Resource check:")
	var missing_resources = []
	for resource_type in building_def["cost"]:
		var required = building_def["cost"][resource_type]
		var available = resource_manager.get_resource_amount(resource_type)
		var resource_name = resource_manager.get_resource_name(resource_type)
		print("- %s: need %d, have %.1f" % [resource_name, required, available])
		
		if available < required:
			missing_resources.append(resource_name)
	
	if missing_resources.size() > 0:
		print("❌ Not enough resources! Missing: ", missing_resources)
		return false
	else:
		print("✅ All resources available")
	
	# Umísti budovu
	place_building(tile_pos, selected_building_type)
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
	
	# Zkontroluj terrain
	for x in range(tile_pos.x, tile_pos.x + size.x):
		for y in range(tile_pos.y, tile_pos.y + size.y):
			var terrain_type = map_generator.terrain_grid[x][y]
			
			# Nelze stavět na vodě/jezeře
			if terrain_type == map_generator.TerrainType.METHANE_SEA:
				return false
			if terrain_type == map_generator.TerrainType.METHANE_LAKE:
				return false
			
			# Zkontroluj kolize s existujícími budovami
			var key = Vector2i(x, y)
			if key in placed_buildings:
				return false
	
	return true

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
		"size": building_def["size"]
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
	
	# Vykresli budovu na mapu (později nahradíme sprite systémem)
	render_building_placeholder(tile_pos, building_def["size"])

func render_building_placeholder(tile_pos: Vector2i, size: Vector2i):
	"""Vykreslí sprite budovy místo TileMap tiles"""
	print("Rendering building sprite at: ", tile_pos, " size: ", size)
	
	# Vytvoř Sprite2D node
	var building_sprite = Sprite2D.new()
	
	# Nastav texturu podle typu budovy
	if selected_building_type in building_textures:
		building_sprite.texture = building_textures[selected_building_type]
		print("Using texture for building type: ", selected_building_type)
	else:
		print("Warning: No texture found for building type: ", selected_building_type)
		# Fallback - použij placeholder barvu
		create_placeholder_sprite(building_sprite, size)
	
	# Vypočítej pozici (střed budovy)
	var world_pos = Vector2(
		(tile_pos.x + size.x / 2.0) * 64,  # 64 = TILE_SIZE
		(tile_pos.y + size.y / 2.0) * 64
	)
	building_sprite.position = world_pos
	
	# Nastav scale podle velikosti budovy (volitelné)
	var scale_factor = Vector2(1.0, 1.0)  # Začneme s 1:1
	if building_sprite.texture:
		scale_factor = Vector2(
			size.x * 64.0 / building_sprite.texture.get_width(),
			size.y * 64.0 / building_sprite.texture.get_height()
		)
	building_sprite.scale = scale_factor
	
	# Přidej do scény
	get_parent().add_child(building_sprite)
	building_sprites.append(building_sprite)
	
	# Ulož referenci do building data
	var building_data = placed_buildings[Vector2i(tile_pos.x, tile_pos.y)]
	if building_data:
		building_data["sprite"] = building_sprite
	
	print("Building sprite created at world position: ", world_pos)

func get_building_source_id() -> int:
	"""Vrátí source ID podle typu budovy"""
	match selected_building_type:
		BuildingType.HABITAT:
			return 0  # basic (oranžová)
		BuildingType.POWER_GENERATOR:
			return 2  # mountain (šedá)
		BuildingType.FARM:
			return 1  # lake (modrá)
		BuildingType.WATER_EXTRACTOR:
			return 3  # sea (tmavě modrá)  
		BuildingType.METHANE_PROCESSOR:
			return 2  # mountain (šedá)
		_:
			return 2  # default mountain

func update_building_preview():
	"""Aktualizuje náhled budovy při pohybu myši"""
	if not is_building_mode:
		return
	
	clear_building_preview()
	
	var mouse_pos = get_global_mouse_position()
	var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
	var building_def = building_definitions[selected_building_type]
	
	# Zkontroluj validitu pozice
	var position_valid = is_valid_building_position(tile_pos, building_def["size"])
	
	# Zkontroluj dostupnost zdrojů
	var resources_available = resource_manager.can_afford(building_def["cost"])
	
	# Celková validita = pozice OK A zdroje OK
	var is_valid = position_valid and resources_available
	
		# Vytvoř preview sprite
	create_preview_sprite(tile_pos, building_def["size"], is_valid)
	
	# Vytvoř outline pouze po vnějším obvodu
	create_preview_outline_clean(tile_pos, building_def["size"], is_valid)

func create_preview_sprite(tile_pos: Vector2i, size: Vector2i, is_valid: bool):
	"""Vytvoří semi-transparentní preview sprite budovy"""
	if not selected_building_type in building_textures:
		return
	
	preview_sprite = Sprite2D.new()
	preview_sprite.texture = building_textures[selected_building_type]
	
	# Pozice (střed budovy)
	var world_pos = Vector2(
		(tile_pos.x + size.x / 2.0) * 64,
		(tile_pos.y + size.y / 2.0) * 64
	)
	preview_sprite.position = world_pos
	
	# Scale podle velikosti
	if preview_sprite.texture:
		var scale_factor = Vector2(
			size.x * 64.0 / preview_sprite.texture.get_width(),
			size.y * 64.0 / preview_sprite.texture.get_height()
		)
		preview_sprite.scale = scale_factor
	
	# Semi-transparentní a barevný podle validity
	if is_valid:
		preview_sprite.modulate = Color(0.8, 1.0, 0.8, 0.7)  # Mírně zelenkavé zabarvení
	else:
		preview_sprite.modulate = Color(1.0, 0.6, 0.6, 0.7)  # Červenkaté zabarvení
	
	# Přidej do scény
	get_parent().add_child(preview_sprite)



func clear_building_preview():
	"""Vyčistí náhled budovy včetně sprite a outline"""
	# Smaž preview sprite
	if preview_sprite:
		preview_sprite.queue_free()
		preview_sprite = null
	
	# Smaž všechny outline elementy
	for outline_element in preview_outline:
		if outline_element:
			outline_element.queue_free()
	preview_outline.clear()
	
	# Vyčisti původní building_preview_tiles (pokud se stále používá)
	building_preview_tiles.clear()
	
func reset_buildings():
	"""Resetuje všechny budovy při regeneraci mapy"""
	print("=== RESETTING BUILDINGS ===")
	
	# Smaž všechny building sprites
	for sprite in building_sprites:
		if sprite and sprite.get_parent():
			sprite.queue_free()
	building_sprites.clear()
	
	# Vyčisti buildings layer (pokud se stále používá)
	if tilemap.get_layers_count() > 1:
		tilemap.clear_layer(1)
		print("Buildings layer cleared")
	
	# Reset building data
	placed_buildings.clear()
	
	# Exit building mode pokud je aktivní
	if is_building_mode:
		exit_building_mode()
	
	print("All buildings and sprites reset")
	
func create_placeholder_sprite(sprite: Sprite2D, size: Vector2i):
	"""Vytvoří placeholder texturu pokud originál chybí"""
	# Vytvoř jednoduchou barevnou texturu
	var image = Image.create(64 * size.x, 64 * size.y, false, Image.FORMAT_RGB8)
	image.fill(Color.MAGENTA)  # Jasně růžová pro debug
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	sprite.texture = texture

func destroy_building(tile_pos: Vector2i):
	# Najdi building data
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		var building_type = building_data["type"]
		var building_def = building_definitions[building_type]
		
		# Odeber production/consumption
		for resource_type in building_def["production"]:
			resource_manager.remove_production(resource_type, building_def["production"][resource_type])
		for resource_type in building_def["consumption"]:
			resource_manager.remove_consumption(resource_type, building_def["consumption"][resource_type])
		
		# Smaž sprite
		if "sprite" in building_data and building_data["sprite"]:
			building_data["sprite"].queue_free()
		
		# Smaž ze všech tiles
		var size = building_def["size"]
		var start_pos = building_data["position"]
		for x in range(start_pos.x, start_pos.x + size.x):
			for y in range(start_pos.y, start_pos.y + size.y):
				var key = Vector2i(x, y)
				if key in placed_buildings:
					placed_buildings.erase(key)
		
		print("Building destroyed at: ", tile_pos)

func damage_building(tile_pos: Vector2i, damage_percent: float):
	# Vizuální efekt damage (červené zabarvení apod.)
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		if "sprite" in building_data and building_data["sprite"]:
			building_data["sprite"].modulate = Color(1, 0.5, 0.5)  # Červené zabarvení
		print("Building damaged at: ", tile_pos, " (", damage_percent * 100, "%)")

func get_all_buildings() -> Array:
	"""Vrátí seznam pozic všech budov (pro WeatherSystem)"""
	var building_positions = []
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		# Přidej jen jednou per building (multi-tile budovy mají více keys)
		if building_id != -1 and not building_id in processed_buildings:
			building_positions.append(building_data.get("position", building_pos))
			processed_buildings[building_id] = true
	
	return building_positions

func get_building_count() -> int:
	"""Vrátí počet budov"""
	return get_all_buildings().size()

func get_buildings_by_type(building_type: BuildingType) -> Array:
	"""Vrátí seznam budov konkrétního typu"""
	var buildings_of_type = []
	var processed_buildings = {}
	
	for building_pos in placed_buildings:
		var building_data = placed_buildings[building_pos]
		var building_id = building_data.get("id", -1)
		
		if building_id != -1 and not building_id in processed_buildings:
			if building_data.get("type", null) == building_type:
				buildings_of_type.append(building_data.get("position", building_pos))
				processed_buildings[building_id] = true
	
	return buildings_of_type

func is_building_at_position(tile_pos: Vector2i) -> bool:
	"""Kontroluje zda je na pozici budova"""
	return tile_pos in placed_buildings

func get_building_at_position(tile_pos: Vector2i) -> Dictionary:
	"""Vrátí data budovy na pozici"""
	if tile_pos in placed_buildings:
		return placed_buildings[tile_pos]
	return {}

func get_building_info_at_position(tile_pos: Vector2i) -> Dictionary:
	"""Vrátí detailní informace o budově na pozici"""
	if not tile_pos in placed_buildings:
		return {}
	
	var building_data = placed_buildings[tile_pos]
	var building_type = building_data.get("type", -1)
	var building_def = building_definitions.get(building_type, {})
	
	return {
		"data": building_data,
		"definition": building_def,
		"type": building_type,
		"name": building_def.get("name", "Unknown"),
		"is_damaged": building_data.get("damage", 0.0) > 0.0,
		"damage_percent": building_data.get("damage", 0.0) * 100,
		"operational": building_data.get("damage", 0.0) < 1.0
	}

# Vylepšené damage funkce s vizuálními efekty
func damage_building_at_position(tile_pos: Vector2i, damage_percent: float):
	"""Poškodí budovu na dané pozici s vizuálními efekty"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		
		# Nastav damage level do building data
		building_data["damage"] = building_data.get("damage", 0.0) + damage_percent
		
		# Vizuální efekt podle úrovně damage
		if "sprite" in building_data and building_data["sprite"]:
			var sprite = building_data["sprite"]
			var total_damage = building_data["damage"]
			
			if total_damage > 0.75:  # 75%+ damage - velmi červené
				sprite.modulate = Color(1, 0.2, 0.2)
			elif total_damage > 0.5:  # 50%+ damage - červené
				sprite.modulate = Color(1, 0.4, 0.4)
			elif total_damage > 0.25:  # 25%+ damage - oranžové
				sprite.modulate = Color(1, 0.7, 0.4)
			else:  # Mírné poškození - žluté
				sprite.modulate = Color(1, 1, 0.6)
			
			# Animace bliknutí při damage
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.5, 0.1)
			tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		
		print("Building damaged at: ", tile_pos, " (", damage_percent * 100, "% damage, total: ", building_data["damage"] * 100, "%)")
		
		# Automatické zničení při vysokém damage
		if building_data["damage"] >= 1.0:
			print("Building auto-destroyed due to excessive damage")
			destroy_building_at_position(tile_pos)

func destroy_building_at_position(tile_pos: Vector2i):
	"""Zničí budovu s particle efekty"""
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
			
			# Animace zničení
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
		
		print("Building destroyed successfully")

# Repair funkcionalita
func repair_building_at_position(tile_pos: Vector2i, repair_amount: float = 1.0):
	"""Opraví budovu na pozici"""
	if tile_pos in placed_buildings:
		var building_data = placed_buildings[tile_pos]
		
		if "damage" in building_data:
			building_data["damage"] = max(0.0, building_data["damage"] - repair_amount)
			
			# Obnov normální barvu při plné opravě
			if building_data["damage"] <= 0.0 and "sprite" in building_data:
				building_data["sprite"].modulate = Color.WHITE
			
			print("Building repaired at: ", tile_pos, " (remaining damage: ", building_data["damage"] * 100, "%)")

# Debug funkce
func debug_damage_all_buildings(damage_percent: float):
	"""Poškodí všechny budovy (pro testing)"""
	for building_pos in get_all_buildings():
		damage_building_at_position(Vector2i(building_pos.x, building_pos.y), damage_percent)

func debug_repair_all_buildings():
	"""Opraví všechny budovy (pro testing)"""
	for building_pos in get_all_buildings():
		repair_building_at_position(Vector2i(building_pos.x, building_pos.y), 1.0)
