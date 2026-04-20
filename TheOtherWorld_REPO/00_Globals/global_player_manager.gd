extends Node

# 1. PRECARGAS
const PLAYER = preload("res://Player/player.tscn")
const MICHAEL_SCENE = preload("res://Player/michael.tscn") 
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

# 2. VARIABLES DE ESTADO Y PROGRESIÓN
var elizabeth : Player
var michael : CharacterBody2D
var player : CharacterBody2D 
var player_spawned : bool = false

# Lógica de la Placa y Cambio
var puede_cambiar_a_michael : bool = false # Se activa con la placa
var ya_cambio_una_vez : bool = false       # Bloquea el regreso

var current_xp : int = 0
var current_level : int = 1
var level_requirements = [ 0, 5, 10, 20, 40, 80, 160 ]

func _ready() -> void:
	elizabeth = PLAYER.instantiate()
	michael = MICHAEL_SCENE.instantiate()
	player = elizabeth 
	
	add_child(elizabeth)
	add_child(michael)
	
	_desactivar_personaje(elizabeth)
	_desactivar_personaje(michael)

# --- SISTEMA DE INPUT (C e H) ---
func _unhandled_input(event: InputEvent) -> void:
	# Interacción (Tecla C)
	if event.is_action_pressed("interact"):
		interact()

	# Cambio a Michael (Tecla H)
	if event.is_action_pressed("cambiar_personaje"):
		if puede_cambiar_a_michael and not ya_cambio_una_vez:
			ya_cambio_una_vez = true 
			viaje_unico_a_michael()
		else:
			if ya_cambio_una_vez:
				print("Ya eres Michael, no hay vuelta atrás.")
			else:
				print("La placa no ha sido activada.")

func viaje_unico_a_michael() -> void:
	# Sacamos a Elizabeth del mapa
	if elizabeth.get_parent() and elizabeth.get_parent() != self:
		elizabeth.get_parent().remove_child(elizabeth)
		add_child(elizabeth)
	_desactivar_personaje(elizabeth)

	# El jefe ahora es Michael
	player = michael
	
	var path_escena : String = "res://Levels/Dungeon01/02.tscn"
	var lm = get_node_or_null("/root/GlobalLevelManager")
	if not lm: lm = get_node_or_null("/root/LevelManager")
	
	if lm:
		# AJUSTA ESTO: Pon la posición X, Y donde debe aparecer Michael en la Dungeon
		var spawn_dungeon = Vector2(200, 200) 
		lm.load_new_level(path_escena, "", Vector2.ZERO, spawn_dungeon)

func interact() -> void:
	if is_instance_valid(player):
		if player.has_method("player_interact"):
			player.player_interact()
		elif player.has_method("interact"):
			player.interact()
		else:
			interact_pressed.emit()

# --- UTILIDADES Y POSICIONAMIENTO ---
func set_player_position(_new_pos: Vector2) -> void:
	if is_instance_valid(player):
		if player.get_parent() != get_tree().current_scene:
			if player.get_parent(): player.get_parent().remove_child(player)
			get_tree().current_scene.add_child(player)
		
		player.global_position = _new_pos
		_activar_personaje(player)
		player_spawned = true
		reset_camera_on_player()

func _activar_personaje(node: CharacterBody2D) -> void:
	node.visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
	var sm = node.get_node_or_null("StateMachine")
	if sm: sm.process_mode = Node.PROCESS_MODE_INHERIT

func _desactivar_personaje(node: CharacterBody2D) -> void:
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED

func reset_camera_on_player(_duration: float = 0.0) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera) and is_instance_valid(player):
		if camera.get_parent(): camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()

# --- FUNCIONES DE SOPORTE PARA OTROS SCRIPTS ---
func set_as_parent(_p: Node2D) -> void:
	if not is_instance_valid(_p) or not is_instance_valid(player): return
	if player.get_parent(): player.get_parent().remove_child(player)
	_p.add_child(player)

func unparent_player(_p: Node2D) -> void:
	if not is_instance_valid(_p) or not is_instance_valid(player): return
	if player.get_parent() == _p: 
		_p.remove_child(player)
		add_child(player)

func set_health(hp: int, max_hp: int) -> void:
	if is_instance_valid(player):
		player.max_hp = max_hp
		player.hp = hp
		if is_instance_valid(get_node_or_null("/root/PlayerHud")):
			get_node("/root/PlayerHud").update_hp(hp, max_hp)

func play_audio(_audio_stream: AudioStream) -> void:
	if is_instance_valid(get_node_or_null("/root/PlayerHud")):
		get_node("/root/PlayerHud").play_audio(_audio_stream)

func force_player_reset() -> void:
	if not is_instance_valid(player): return
	var sm = player.get_node_or_null("StateMachine")
	if sm:
		for state in sm.get_children():
			if "idle" in state.name.to_lower():
				sm.change_state(state)
				break

func shake_camera(trauma: float = 1) -> void:
	camera_shook.emit(clamp(trauma, 0, 3))

func reward_xp(amount: int) -> void:
	current_xp += amount
	if current_level < level_requirements.size():
		if current_xp >= level_requirements[current_level]:
			current_level += 1
			player_leveled_up.emit()
