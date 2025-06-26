# === TITAN QUEST - DEN 1 (FINÁLNÍ VERZE) ===
# MapGenerator.gd - Základní tile-based mapa s procedurální generací

extends Node2D

# Konstanty pro mapu
const MAP_WIDTH = 20
const MAP_HEIGHT = 20
const TILE_SIZE = 64

# Typy terrain
enum TerrainType {
	NORMAL_SURFACE,
	METHANE_SEA,
	METHANE_LAKE,
	ICE_MOUNTAINS
}

# Tilemap reference
@onready var tilemap: TileMap = $TileMap

# Mapa terrain dat
var terrain_grid: Array[Array] = []

func _ready():
	print("=== TITAN QUEST STARTING ===")
	setup_tilemap()
	generate_map()
	render_map()

func setup_tilemap():
	"""Nastavení TileMap node"""
	if not tilemap:
		print("TileMap node not found!")
		return
	
	if not tilemap.tile_set:
		print("TileSet not assigned! Please assign terrain_tileset.tres to TileMap")
		return
	
	print("TileMap setup complete - ", tilemap.tile_set.get_source_count(), " sources available")

func generate_map():
	"""Procedurální generování mapy podle specifikací"""
	print("Generating procedural map...")
	
	# Inicializace gridu
	terrain_grid.clear()
	for x in range(MAP_WIDTH):
		terrain_grid.append([])
		for y in range(MAP_HEIGHT):
			terrain_grid[x].append(TerrainType.NORMAL_SURFACE)
	
	# 1. Generování oceánu na krajích
	generate_methane_seas()
	
	# 2. Generování jezer - GARANTOVANÉ ALESPOŇ 1
	generate_methane_lakes()
	
	# 3. Generování hor - GARANTOVANÉ ALESPOŇ 1, VÍCE MNOŽSTVÍ
	generate_mountains()

func generate_methane_seas():
	"""Generuje metanové moře na krajích mapy"""
	# Horní a dolní okraj
	for x in range(MAP_WIDTH):
		# Horní okraj (první 2-3 řádky)
		var sea_depth = randi_range(2, 3)
		for y in range(sea_depth):
			if y < MAP_HEIGHT:
				terrain_grid[x][y] = TerrainType.METHANE_SEA
		
		# Dolní okraj (poslední 2-3 řádky)
		sea_depth = randi_range(2, 3)
		for y in range(MAP_HEIGHT - sea_depth, MAP_HEIGHT):
			if y >= 0:
				terrain_grid[x][y] = TerrainType.METHANE_SEA
	
	# Levý a pravý okraj
	for y in range(MAP_HEIGHT):
		# Levý okraj (první 2-3 sloupce)
		var sea_depth = randi_range(2, 3)
		for x in range(sea_depth):
			if x < MAP_WIDTH:
				terrain_grid[x][y] = TerrainType.METHANE_SEA
		
		# Pravý okraj (poslední 2-3 sloupce)  
		sea_depth = randi_range(2, 3)
		for x in range(MAP_WIDTH - sea_depth, MAP_WIDTH):
			if x >= 0:
				terrain_grid[x][y] = TerrainType.METHANE_SEA

func generate_methane_lakes():
	"""Generuje GARANTOVANĚ 1-3 metanová jezera ve vnitrozemí"""
	var num_lakes = randi_range(1, 3)
	var lakes_placed = 0
	print("Attempting to generate ", num_lakes, " methane lakes...")
	
	# První jezero - garantované umístění
	var first_lake_placed = false
	var attempts = 0
	
	while not first_lake_placed and attempts < 100:
		var lake_size = randi_range(3, 5)  # Větší jezera pro garantované umístění
		var start_x = randi_range(5, MAP_WIDTH - lake_size - 5)
		var start_y = randi_range(5, MAP_HEIGHT - lake_size - 5)
		
		if can_place_lake(start_x, start_y, lake_size):
			place_lake(start_x, start_y, lake_size)
			lakes_placed += 1
			first_lake_placed = true
			print("✅ GUARANTEED Lake ", lakes_placed, " placed at: (", start_x, ",", start_y, ") size:", lake_size)
		
		attempts += 1
	
	if not first_lake_placed:
		# Fallback - force place smaller lake in center
		var center_x = MAP_WIDTH / 2 - 1
		var center_y = MAP_HEIGHT / 2 - 1
		force_place_lake(center_x, center_y, 2)
		lakes_placed += 1
		print("⚠️ FORCED Lake placement at center: (", center_x, ",", center_y, ")")
	
	# Zbytek jezer - normální umístění
	for i in range(lakes_placed, num_lakes):
		attempts = 0
		var placed = false
		
		while attempts < 50 and not placed:
			var lake_size = randi_range(2, 6)
			var start_x = randi_range(4, MAP_WIDTH - lake_size - 4)
			var start_y = randi_range(4, MAP_HEIGHT - lake_size - 4)
			
			if can_place_lake(start_x, start_y, lake_size):
				place_lake(start_x, start_y, lake_size)
				lakes_placed += 1
				placed = true
				print("✅ Lake ", lakes_placed, " placed at: (", start_x, ",", start_y, ") size:", lake_size)
			
			attempts += 1
		
		if not placed:
			print("⚠️ Could not place additional lake ", i+1, " after 50 attempts")
	
	print("Total lakes placed: ", lakes_placed, "/", num_lakes)

func can_place_lake(start_x: int, start_y: int, size: int) -> bool:
	"""Zkontroluje, zda lze umístit jezero na danou pozici"""
	var width = randi_range(2, size)
	var height = size - width + 2
	height = max(2, min(height, 6))
	
	# Zkontroluj všechny pozice
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			if x >= MAP_WIDTH or y >= MAP_HEIGHT:
				return false
			if terrain_grid[x][y] != TerrainType.NORMAL_SURFACE:
				return false
	
	return true

func place_lake(start_x: int, start_y: int, size: int):
	"""Umístí jezero na danou pozici"""
	var width = randi_range(2, size)
	var height = size - width + 2
	height = max(2, min(height, 6))
	
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			if x < MAP_WIDTH and y < MAP_HEIGHT:
				terrain_grid[x][y] = TerrainType.METHANE_LAKE

func force_place_lake(start_x: int, start_y: int, size: int):
	"""Vynuceně umístí malé jezero (pro garantované umístění)"""
	for x in range(start_x, start_x + size):
		for y in range(start_y, start_y + size):
			if x < MAP_WIDTH and y < MAP_HEIGHT and x >= 0 and y >= 0:
				if terrain_grid[x][y] == TerrainType.NORMAL_SURFACE:
					terrain_grid[x][y] = TerrainType.METHANE_LAKE

func generate_mountains():
	"""Generuje GARANTOVANĚ alespoň 1 ledové hory, celkově více hor"""
	var target_mountains = randi_range(3, 6)  # Zvýšeno z 0-2 na 3-6
	var mountains_placed = 0
	
	print("Attempting to generate ", target_mountains, " mountain regions...")
	
	# První hory - garantované umístění
	var first_mountains_placed = false
	var attempts = 0
	
	while not first_mountains_placed and attempts < 100:
		var mountain_x = randi_range(6, MAP_WIDTH - 6)
		var mountain_y = randi_range(6, MAP_HEIGHT - 6)
		
		if terrain_grid[mountain_x][mountain_y] == TerrainType.NORMAL_SURFACE:
			place_mountain_cluster(mountain_x, mountain_y)
			mountains_placed += 1
			first_mountains_placed = true
			print("✅ GUARANTEED Mountain cluster ", mountains_placed, " placed at: (", mountain_x, ",", mountain_y, ")")
		
		attempts += 1
	
	if not first_mountains_placed:
		# Fallback - force place in available spot
		for x in range(6, MAP_WIDTH - 6):
			for y in range(6, MAP_HEIGHT - 6):
				if terrain_grid[x][y] == TerrainType.NORMAL_SURFACE:
					place_mountain_cluster(x, y)
					mountains_placed += 1
					print("⚠️ FORCED Mountain placement at: (", x, ",", y, ")")
					break
			if mountains_placed > 0:
				break
	
	# Zbytek hor - normální umístění
	var additional_attempts = 0
	while mountains_placed < target_mountains and additional_attempts < 200:
		var mountain_x = randi_range(5, MAP_WIDTH - 5)
		var mountain_y = randi_range(5, MAP_HEIGHT - 5)
		
		if terrain_grid[mountain_x][mountain_y] == TerrainType.NORMAL_SURFACE:
			# Zkontroluj, zda není příliš blízko k existujícím horám
			if not is_too_close_to_mountains(mountain_x, mountain_y, 3):
				place_mountain_cluster(mountain_x, mountain_y)
				mountains_placed += 1
				print("✅ Mountain cluster ", mountains_placed, " placed at: (", mountain_x, ",", mountain_y, ")")
		
		additional_attempts += 1
	
	print("Total mountain clusters placed: ", mountains_placed, "/", target_mountains)

func place_mountain_cluster(center_x: int, center_y: int):
	"""Umístí cluster hor kolem středového bodu"""
	# Hlavní hora
	terrain_grid[center_x][center_y] = TerrainType.ICE_MOUNTAINS
	
	# Okolní hory s pravděpodobností
	var cluster_size = randi_range(2, 4)  # Větší clustery
	
	for dx in range(-cluster_size, cluster_size + 1):
		for dy in range(-cluster_size, cluster_size + 1):
			if dx == 0 and dy == 0:
				continue  # Střed už je nastaven
			
			var nx = center_x + dx
			var ny = center_y + dy
			
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if terrain_grid[nx][ny] == TerrainType.NORMAL_SURFACE:
					# Pravděpodobnost podle vzdálenosti od středu
					var distance = abs(dx) + abs(dy)
					var probability = 0.8 / (distance + 1)  # Vyšší pravděpodobnost blíž ke středu
					
					if randf() < probability:
						terrain_grid[nx][ny] = TerrainType.ICE_MOUNTAINS

func is_too_close_to_mountains(x: int, y: int, min_distance: int) -> bool:
	"""Kontroluje, zda není pozice příliš blízko k existujícím horám"""
	for dx in range(-min_distance, min_distance + 1):
		for dy in range(-min_distance, min_distance + 1):
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if terrain_grid[nx][ny] == TerrainType.ICE_MOUNTAINS:
					return true
	
	return false

func render_map():
	"""Vykreslí mapu do TileMap"""
	if not tilemap or not tilemap.tile_set:
		print("ERROR: Cannot render - TileMap or TileSet missing!")
		return
	
	# Vyčisti existující tiles
	tilemap.clear()
	
	# Vykresli všechny tiles
	var tiles_drawn = 0
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var terrain_type = terrain_grid[x][y]
			var source_id = get_source_id_for_terrain(terrain_type)
			
			# Nastav tile na pozici
			tilemap.set_cell(0, Vector2i(x, y), source_id, Vector2i(0, 0))
			tiles_drawn += 1
	
	print("Map rendered! Tiles drawn: ", tiles_drawn, "/", MAP_WIDTH * MAP_HEIGHT)

func get_source_id_for_terrain(terrain_type: TerrainType) -> int:
	"""Vrátí Source ID pro daný typ terénu"""
	match terrain_type:
		TerrainType.NORMAL_SURFACE:
			return 0  # basic (oranžová)
		TerrainType.METHANE_SEA:
			return 3  # sea (tmavě modrá)
		TerrainType.METHANE_LAKE:
			return 1  # lake (světle modrá)
		TerrainType.ICE_MOUNTAINS:
			return 2  # mountain (šedá/oranžová)
		_:
			return 0

func _input(event):
	"""Input handling pro testování"""
	if event.is_action_pressed("ui_accept"):  # SPACE nebo ENTER
		print("=== REGENERATING MAP ===")
		
		# Reset všech systémů
		reset_game_state()
		
		# Regeneruj mapu
		generate_map()
		render_map()
		print("Map regenerated!")
	
	if event.is_action_pressed("ui_cancel"):  # ESC
		print("=== MAP STATISTICS ===")
		count_terrain_types()

	if event.is_action_pressed("ui_select"):  # TAB key - debug weather
		var weather_system = get_node("WeatherSystem")
		if weather_system:
			weather_system.trigger_random_disaster()
			print("Debug: Triggered random disaster")
		
func reset_game_state():
	"""Resetuje celý herní stav na začátek"""
	print("=== RESETTING GAME STATE ===")
	
	# Reset resources
	if has_node("/root/ResourceManager"):
		var resource_manager = get_node("/root/ResourceManager")
		resource_manager.reset_to_initial_state()
	
	# Reset buildings
	if has_node("BuildingSystem"):
		var building_system = get_node("BuildingSystem")
		building_system.reset_buildings()
	
	# Reset TileInspector (zavři otevřené inspekce)
	if has_node("TileInspector"):
		var tile_inspector = get_node("TileInspector")
		if tile_inspector.has_method("hide_inspection"):
			tile_inspector.hide_inspection()
		print("TileInspector reset")
	
	# Reset Weather System
	if has_node("WeatherSystem"):
		var weather_system = get_node("WeatherSystem")
		if weather_system.has_method("change_weather"):
			weather_system.change_weather(weather_system.WeatherType.CLEAR)
		print("WeatherSystem reset to clear")
	
	# Reset GameManager (pokud existuje)
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if game_manager and game_manager.has_method("reset_statistics"):
		game_manager.reset_statistics()
		print("GameManager statistics reset")
	
	print("Game state reset complete")

func count_terrain_types():
	"""Spočítá a vypíše statistiky terénu"""
	var counts = {
		TerrainType.NORMAL_SURFACE: 0,
		TerrainType.METHANE_SEA: 0,
		TerrainType.METHANE_LAKE: 0,
		TerrainType.ICE_MOUNTAINS: 0
	}
	
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			counts[terrain_grid[x][y]] += 1
	
	print("=== TERRAIN STATISTICS ===")
	print("- Normal surface: ", counts[TerrainType.NORMAL_SURFACE], " tiles (", "%.1f%%" % (counts[TerrainType.NORMAL_SURFACE] * 100.0 / (MAP_WIDTH * MAP_HEIGHT)), ")")
	print("- Methane seas: ", counts[TerrainType.METHANE_SEA], " tiles (", "%.1f%%" % (counts[TerrainType.METHANE_SEA] * 100.0 / (MAP_WIDTH * MAP_HEIGHT)), ")")
	print("- Methane lakes: ", counts[TerrainType.METHANE_LAKE], " tiles (", "%.1f%%" % (counts[TerrainType.METHANE_LAKE] * 100.0 / (MAP_WIDTH * MAP_HEIGHT)), ")")
	print("- Ice mountains: ", counts[TerrainType.ICE_MOUNTAINS], " tiles (", "%.1f%%" % (counts[TerrainType.ICE_MOUNTAINS] * 100.0 / (MAP_WIDTH * MAP_HEIGHT)), ")")
	print("Total: ", counts.values().reduce(func(a, b): return a + b), " tiles")
	
	# Kontrola minimálních požadavků
	var requirements_met = true
	if counts[TerrainType.METHANE_LAKE] == 0:
		print("❌ WARNING: No methane lakes found!")
		requirements_met = false
	if counts[TerrainType.ICE_MOUNTAINS] == 0:
		print("❌ WARNING: No ice mountains found!")
		requirements_met = false
	
	if requirements_met:
		print("✅ All terrain requirements met")

# Debug functions
func debug_force_terrain(x: int, y: int, terrain_type: TerrainType):
	"""Debug funkce pro vynucené umístění terénu"""
	if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
		terrain_grid[x][y] = terrain_type
		render_map()
		print("Forced terrain at (", x, ",", y, ") to type: ", terrain_type)

func debug_print_terrain_around(x: int, y: int, radius: int = 2):
	"""Debug funkce pro výpis terénu kolem pozice"""
	print("=== TERRAIN AROUND (", x, ",", y, ") ===")
	for dy in range(-radius, radius + 1):
		var line = ""
		for dx in range(-radius, radius + 1):
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				match terrain_grid[nx][ny]:
					TerrainType.NORMAL_SURFACE: line += "N "
					TerrainType.METHANE_SEA: line += "S "
					TerrainType.METHANE_LAKE: line += "L "
					TerrainType.ICE_MOUNTAINS: line += "M "
			else:
				line += "X "
		print(line)
