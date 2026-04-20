extends Node

signal level_load_started
signal level_loaded
signal tilemap_bounds_changed( bounds : Array[ Vector2 ] )

var current_tilemap_bounds : Array[ Vector2 ]
var target_transition : String
var position_offset : Vector2

# Control de cambio de personaje (Reset)
var is_switching_character : bool = false
var custom_spawn_pos : Vector2 = Vector2.ZERO

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()

func change_tilemap_bounds( bounds : Array[ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	tilemap_bounds_changed.emit( bounds )

func load_new_level(level_path : String, _target_transition : String, _position_offset : Vector2, _fixed_pos : Vector2 = Vector2.ZERO) -> void:
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	# Si mandamos una posición fija, activamos el modo especial
	if _fixed_pos != Vector2.ZERO:
		is_switching_character = true
		custom_spawn_pos = _fixed_pos
	else:
		is_switching_character = false
	
	if has_node("/root/SceneTransition"):
		await get_node("/root/SceneTransition").fade_out()
	
	level_load_started.emit()
	
	# Cambiar de escena
	var error = get_tree().change_scene_to_file(level_path)
	if error != OK:
		push_error("Error: No se encontró la ruta: ", level_path)
	
	# Esperar a que Godot monte los nodos en memoria
	await get_tree().process_frame
	await get_tree().process_frame
	
	if is_switching_character:
		# Forzamos al PlayerManager a inyectar al personaje en el mapa nuevo
		PlayerManager.set_player_position(custom_spawn_pos)
		is_switching_character = false 
	
	if has_node("/root/SceneTransition"):
		await get_node("/root/SceneTransition").fade_in()
	
	get_tree().paused = false
	level_loaded.emit()
