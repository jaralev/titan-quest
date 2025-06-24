# === TITAN QUEST - CAMERA CONTROLS ===
# Camera2D.gd - Ovládání kamery pro kolonii na Titanu

extends Camera2D

const CAMERA_SPEED = 300
const ZOOM_SPEED = 0.1
const MIN_ZOOM = 0.3
const MAX_ZOOM = 2.0

func _ready():
	print("Camera2D initialized")
	
	# Nastavení počáteční pozice kamery na střed mapy
	var map_center = Vector2(10 * 64, 10 * 64)  # 20x20 mapa, tile 64px
	global_position = map_center
	zoom = Vector2(0.8, 0.8)
	enabled = true

func _process(delta):
	handle_camera_movement(delta)
	handle_camera_zoom()

func handle_camera_movement(delta):
	"""Ovládání pohybu kamery pomocí WASD nebo šipek"""
	var velocity = Vector2.ZERO
		
	# Debug input
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	
	# Normalizuj a aplikuj rychlost
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * CAMERA_SPEED / zoom.x
		global_position += velocity * delta

func handle_camera_zoom():
	"""Ovládání zoomu pomocí kolečka myši"""
	if Input.is_action_just_pressed("wheel_up"):
		zoom_in()
	elif Input.is_action_just_pressed("wheel_down"):
		zoom_out()

func zoom_in():
	var new_zoom = zoom.x + ZOOM_SPEED
	new_zoom = min(new_zoom, MAX_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)

func zoom_out():
	var new_zoom = zoom.x - ZOOM_SPEED
	new_zoom = max(new_zoom, MIN_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)
