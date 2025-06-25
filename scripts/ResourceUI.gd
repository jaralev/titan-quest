# ===========================================
# SOUBOR: ResourceUI.gd
# ===========================================
# UI pro zobrazení zdrojů - připojte k Control node

extends Control

@onready var resource_manager: Node = get_node("/root/ResourceManager")

# UI elementy - vytvořte je v editoru nebo kódem
var resource_labels = {}
var resource_bars = {}

func _ready():
	print("ResourceUI initialized")
	create_resource_ui()
	
	# Připojte signály
	if resource_manager:
		resource_manager.resource_changed.connect(_on_resource_changed)

func create_resource_ui():
	"""Vytvoří UI pro všechny zdroje"""
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Nastavení pozice v levém horním rohu
	position = Vector2(10, 10)
	
	for resource_type in ResourceManager.ResourceType.values():
		var resource_panel = create_resource_panel(resource_type)
		vbox.add_child(resource_panel)

func create_resource_panel(resource_type: ResourceManager.ResourceType) -> Control:
	"""Vytvoří panel pro jeden zdroj"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 40)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Název zdroje
	var name_label = Label.new()
	name_label.text = resource_manager.get_resource_name(resource_type)
	name_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(name_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(100, 20)
	progress_bar.max_value = resource_manager.max_capacity[resource_type]
	progress_bar.value = resource_manager.current_resources[resource_type]
	hbox.add_child(progress_bar)
	resource_bars[resource_type] = progress_bar
	
	# Amount label
	var amount_label = Label.new()
	amount_label.custom_minimum_size = Vector2(60, 0)
	update_amount_label(amount_label, resource_type)
	hbox.add_child(amount_label)
	resource_labels[resource_type] = amount_label
	
	return panel

func update_amount_label(label: Label, resource_type: ResourceManager.ResourceType):
	"""Aktualizuje text labelu s množstvím"""
	var current = resource_manager.get_resource_amount(resource_type)
	var net_rate = resource_manager.get_net_rate(resource_type)
	var unit = resource_manager.get_resource_unit(resource_type)
	
	var rate_text = ""
	if net_rate > 0:
		rate_text = " (+%.1f/s)" % net_rate
	elif net_rate < 0:
		rate_text = " (%.1f/s)" % net_rate
	
	label.text = "%.0f%s%s" % [current, unit, rate_text]
	
	# Barva podle stavu
	if net_rate < 0 and current < 20:
		label.modulate = Color.RED
	elif net_rate < 0:
		label.modulate = Color.YELLOW
	else:
		label.modulate = Color.WHITE

func _on_resource_changed(resource_type: ResourceManager.ResourceType, amount: float):
	"""Callback při změně zdroje"""
	if resource_type in resource_bars:
		resource_bars[resource_type].value = amount
	
	if resource_type in resource_labels:
		update_amount_label(resource_labels[resource_type], resource_type)
