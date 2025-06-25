# ===========================================
# SOUBOR: ResourceManager.gd
# ===========================================
# Správa všech zdrojů v kolonii

extends Node

# Typy zdrojů
enum ResourceType {
	ENERGY,
	OXYGEN,
	FOOD,
	WATER,
	METHANE,
	BUILDING_MATERIALS
}

# Aktuální množství zdrojů - VÍCE PRO TESTOVÁNÍ
var current_resources = {
	ResourceType.ENERGY: 2000.0,      # Zvýšeno z 100
	ResourceType.OXYGEN: 1000.0,      # Zvýšeno z 50
	ResourceType.FOOD: 800.0,         # Zvýšeno z 30
	ResourceType.WATER: 1000.0,       # Zvýšeno z 40
	ResourceType.METHANE: 1500.0,     # Zvýšeno z 80
	ResourceType.BUILDING_MATERIALS: 1000.0  # Zvýšeno z 20
}

# Production rates (za sekundu)
var production_rates = {
	ResourceType.ENERGY: 0.0,
	ResourceType.OXYGEN: 0.0,
	ResourceType.FOOD: 0.0,
	ResourceType.WATER: 0.0,
	ResourceType.METHANE: 0.0,
	ResourceType.BUILDING_MATERIALS: 0.0
}

# Consumption rates (za sekundu)
var consumption_rates = {
	ResourceType.ENERGY: 2.0,
	ResourceType.OXYGEN: 1.5,
	ResourceType.FOOD: 1.0,
	ResourceType.WATER: 1.2,
	ResourceType.METHANE: 0.5,
	ResourceType.BUILDING_MATERIALS: 0.0
}

# Maximum capacity
var max_capacity = {
	ResourceType.ENERGY: 500.0,
	ResourceType.OXYGEN: 200.0,
	ResourceType.FOOD: 150.0,
	ResourceType.WATER: 200.0,
	ResourceType.METHANE: 300.0,
	ResourceType.BUILDING_MATERIALS: 100.0
}

# Signály
signal resource_changed(resource_type: ResourceType, amount: float)
signal resource_depleted(resource_type: ResourceType)
signal resource_full(resource_type: ResourceType)

func _ready():
	print("ResourceManager initialized")
	# Update resources každou sekundu
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_resources)
	timer.autostart = true
	add_child(timer)

func _update_resources():
	"""Aktualizuje zdroje každou sekundu"""
	for resource_type in ResourceType.values():
		var net_change = production_rates[resource_type] - consumption_rates[resource_type]
		var old_amount = current_resources[resource_type]
		var new_amount = old_amount + net_change
		
		# Clamp to capacity
		new_amount = clamp(new_amount, 0.0, max_capacity[resource_type])
		
		# Update amount
		current_resources[resource_type] = new_amount
		
		# Emit signals
		if new_amount != old_amount:
			resource_changed.emit(resource_type, new_amount)
		
		if new_amount <= 0.0 and old_amount > 0.0:
			resource_depleted.emit(resource_type)
			print("WARNING: ", get_resource_name(resource_type), " depleted!")
		
		if new_amount >= max_capacity[resource_type] and old_amount < max_capacity[resource_type]:
			resource_full.emit(resource_type)

func get_resource_amount(resource_type: ResourceType) -> float:
	"""Vrátí aktuální množství zdroje"""
	return current_resources[resource_type]

func can_afford(costs: Dictionary) -> bool:
	"""Zkontroluje zda má dostatek zdrojů"""
	for resource_type in costs:
		if current_resources[resource_type] < costs[resource_type]:
			return false
	return true

func spend_resources(costs: Dictionary) -> bool:
	"""Utratí zdroje pokud je to možné"""
	if not can_afford(costs):
		return false
	
	for resource_type in costs:
		current_resources[resource_type] -= costs[resource_type]
		resource_changed.emit(resource_type, current_resources[resource_type])
	
	return true

func add_production(resource_type: ResourceType, amount: float):
	"""Přidá production rate"""
	production_rates[resource_type] += amount

func remove_production(resource_type: ResourceType, amount: float):
	"""Odebere production rate"""
	production_rates[resource_type] -= amount

func add_consumption(resource_type: ResourceType, amount: float):
	"""Přidá consumption rate"""
	consumption_rates[resource_type] += amount

func remove_consumption(resource_type: ResourceType, amount: float):
	"""Odebere consumption rate"""
	consumption_rates[resource_type] -= amount

func get_net_rate(resource_type: ResourceType) -> float:
	"""Vrátí čistou změnu za sekundu"""
	return production_rates[resource_type] - consumption_rates[resource_type]

func get_resource_name(resource_type: ResourceType) -> String:
	"""Vrátí lidsky čitelný název zdroje"""
	match resource_type:
		ResourceType.ENERGY:
			return "Energy"
		ResourceType.OXYGEN:
			return "Oxygen"
		ResourceType.FOOD:
			return "Food"
		ResourceType.WATER:
			return "Water"
		ResourceType.METHANE:
			return "Methane"
		ResourceType.BUILDING_MATERIALS:
			return "Materials"
		_:
			return "Unknown"

func reset_to_initial_state():
	"""Resetuje všechny zdroje na počáteční hodnoty"""
	print("=== RESETTING RESOURCES ===")
	
	current_resources = {
		ResourceType.ENERGY: 2000.0,
		ResourceType.OXYGEN: 1000.0,
		ResourceType.FOOD: 800.0,
		ResourceType.WATER: 1000.0,
		ResourceType.METHANE: 1500.0,
		ResourceType.BUILDING_MATERIALS: 500.0
	}
	
	# Reset production/consumption rates
	production_rates = {
		ResourceType.ENERGY: 0.0,
		ResourceType.OXYGEN: 0.0,
		ResourceType.FOOD: 0.0,
		ResourceType.WATER: 0.0,
		ResourceType.METHANE: 0.0,
		ResourceType.BUILDING_MATERIALS: 0.0
	}
	
	consumption_rates = {
		ResourceType.ENERGY: 2.0,
		ResourceType.OXYGEN: 1.5,
		ResourceType.FOOD: 1.0,
		ResourceType.WATER: 1.2,
		ResourceType.METHANE: 0.5,
		ResourceType.BUILDING_MATERIALS: 0.0
	}
	
	# Emit signals pro všechny zdroje
	for resource_type in ResourceType.values():
		resource_changed.emit(resource_type, current_resources[resource_type])
	
	print("Resources reset to initial values")

func get_resource_unit(resource_type: ResourceType) -> String:
	"""Vrátí jednotku zdroje"""
	match resource_type:
		ResourceType.ENERGY:
			return "kW"
		ResourceType.OXYGEN:
			return "kg"
		ResourceType.FOOD:
			return "kg"
		ResourceType.WATER:
			return "L"
		ResourceType.METHANE:
			return "L"
		ResourceType.BUILDING_MATERIALS:
			return "units"
		_:
			return ""
