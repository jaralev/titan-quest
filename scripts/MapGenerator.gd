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
	
	# 2. Generování 1-3 jezer ve vnitrozemí
	generate_methane_lakes()
	
	# 3. Generování hor (volitelně)
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
	"""Generuje 1-3 metanová jezera ve vnitrozemí"""
	var num_lakes = randi_range(1, 3)
	print("Generating ", num_lakes, " methane lakes...")
	
	for i in range(num_lakes):
		# Najdi pozici ve vnitrozemí (ne na kraji)
		var attempts = 0
		var placed = false
		
		while attempts < 50 and not placed:
			var lake_size = randi_range(2, 6)
			var start_x = randi_range(4, MAP_WIDTH - lake_size - 4)
			var start_y = randi_range(4, MAP_HEIGHT - lake_size - 4)
			
			# Zkontroluj, zda je prostor volný
			if can_place_lake(start_x, start_y, lake_size):
				place_lake(start_x, start_y, lake_size)
				placed = true
				print("Lake ", i+1, " placed at: (", start_x, ",", start_y, ") size:", lake_size)
			
			attempts += 1
		
		if not placed:
			print("Could not place lake ", i+1, " after 50 attempts")

func can_place_lake(start_x: int, start_y: int, size: int) -> bool:
	"""Zkontroluje, zda lze umístit jezero na danou pozici"""
	# Jezero musí být čtvercové nebo obdélníkové
	var width = randi_range(2, size)
	var height = size - width + 2 # Jednoduchá variace
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
	
	# Umísti jezero
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			if x < MAP_WIDTH and y < MAP_HEIGHT:
				terrain_grid[x][y] = TerrainType.METHANE_LAKE

func generate_mountains():
	"""Generuje ledové hory (volitelně)"""
	var num_mountains = randi_range(0, 2)
	
	if num_mountains > 0:
		print("Generating ", num_mountains, " mountain regions...")
	
	for i in range(num_mountains):
		var mountain_x = randi_range(6, MAP_WIDTH - 6)
		var mountain_y = randi_range(6, MAP_HEIGHT - 6)
		
		if terrain_grid[mountain_x][mountain_y] == TerrainType.NORMAL_SURFACE:
			terrain_grid[mountain_x][mountain_y] = TerrainType.ICE_MOUNTAINS
			
			# Přidej nějaké okolní horské oblasti
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var nx = mountain_x + dx
					var ny = mountain_y + dy
					if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
						if terrain_grid[nx][ny] == TerrainType.NORMAL_SURFACE and randf() < 0.3:
							terrain_grid[nx][ny] = TerrainType.ICE_MOUNTAINS

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
	
	print("Terrain statistics:")
	print("- Normal surface: ", counts[TerrainType.NORMAL_SURFACE], " tiles")
	print("- Methane seas: ", counts[TerrainType.METHANE_SEA], " tiles") 
	print("- Methane lakes: ", counts[TerrainType.METHANE_LAKE], " tiles")
	print("- Ice mountains: ", counts[TerrainType.ICE_MOUNTAINS], " tiles")
	print("Total: ", counts.values().reduce(func(a, b): return a + b), " tiles")
