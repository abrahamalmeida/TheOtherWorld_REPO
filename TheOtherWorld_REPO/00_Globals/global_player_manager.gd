extends Node

# 1. PRECARGAS
const PLAYER = preload("res://Player/player.tscn")
const MICHAEL_SCENE = preload("res://Player/michael.tscn") 
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

# 2. VARIABLES
var elizabeth : Player
var michael : CharacterBody2D
var player : CharacterBody2D 
var player_spawned : bool = false

# Un solo candado interno para que no se dispare dos veces si pisas raro
var ya_viajamos : bool = false       

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
	ya_viajamos = false

# --- SISTEMA DE INPUT (SOLO LA C) ---
func _unhandled_input(event: InputEvent) -> void:
	# Interacción (Tecla C)
	if event.is_action_pressed("interact"):
		interact()
	# ADIÓS A LA TECLA H. YA NO EXISTE AQUÍ.

# --- EL VIAJE AUTOMÁTICO ---
func viaje_unico_a_michael() -> void:
	# Si ya viajamos, ignoramos cualquier otra llamada
	if ya_viajamos: return
	ya_viajamos = true 

	if elizabeth.get_parent() and elizabeth.get_parent() != self:
		elizabeth.get_parent().remove_child(elizabeth)
		add_child(elizabeth)
	_desactivar_personaje(elizabeth)

	player = michael
	var path_escena : String = "res://Levels/Dungeon01/02.tscn"
	var lm = get_node_or_null("/root/GlobalLevelManager")
	if not lm: lm = get_node_or_null("/root/LevelManager")
	
	if lm:
		# Coordenada de aparición
		var spawn_pos = Vector2(250, 250) 
		lm.load_new_level(path_escena, "", Vector2.ZERO, spawn_pos)

# --- TODAS LAS FUNCIONES VITALES (INTACTAS) ---

func unparent_player(_p: Node2D) -> void:
	if not is_instance_valid(_p) or not is_instance_valid(player): return
	if player.get_parent() == _p: 
		_p.remove_child(player)
		add_child(player)

func force_player_reset() -> void:
	if not is_instance_valid(player): return
	var sm = player.get_node_or_null("StateMachine")
	if sm:
		for state in sm.get_children():
			if "idle" in state.name.to_lower():
				sm.change_state(state)
				break

func interact() -> void:
	if is_instance_valid(player):
		if player.has_method("player_interact"):
			player.player_interact()
		elif player.has_method("interact"):
			player.interact()
		else:
			interact_pressed.emit()

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

func set_as_parent(_p: Node2D) -> void:
	if not is_instance_valid(_p) or not is_instance_valid(player): return
	if player.get_parent(): player.get_parent().remove_child(player)
	_p.add_child(player)

func set_health(hp: int, max_hp: int) -> void:
	if is_instance_valid(player):
		player.max_hp = max_hp
		player.hp = hp
		if is_instance_valid(get_node_or_null("/root/PlayerHud")):
			get_node("/root/PlayerHud").update_hp(hp, max_hp)

func play_audio(_audio_stream: AudioStream) -> void:
	if is_instance_valid(get_node_or_null("/root/PlayerHud")):
		get_node("/root/PlayerHud").play_audio(_audio_stream)

func reset_camera_on_player(_duration: float = 0.0) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera) and is_instance_valid(player):
		if camera.get_parent(): camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()

func shake_camera(trauma: float = 1) -> void:
	camera_shook.emit(clamp(trauma, 0, 3))

func reward_xp(amount: int) -> void:
	current_xp += amount
	if current_level < level_requirements.size():
		if current_xp >= level_requirements[current_level]:
			current_level += 1
			player_leveled_up.emit()
