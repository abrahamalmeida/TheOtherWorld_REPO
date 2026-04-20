extends Node

# 1. PRECARGAS
const PLAYER = preload("res://Player/player.tscn")
const MICHAEL_SCENE = preload("res://Player/michael.tscn") 
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

var interact_handled : bool = true
var level_requirements = [ 0, 5, 10, 20, 40 ]

# 2. VARIABLES DE PERSONAJES
var elizabeth : Player
var michael : CharacterBody2D
var player : CharacterBody2D 
var player_spawned : bool = false

func _ready() -> void:
	elizabeth = PLAYER.instantiate()
	michael = MICHAEL_SCENE.instantiate()
	
	player = elizabeth # Elizabeth por defecto
	
	add_child(elizabeth)
	add_child(michael)
	
	elizabeth.visible = false
	elizabeth.process_mode = Node.PROCESS_MODE_DISABLED
	michael.visible = false
	michael.process_mode = Node.PROCESS_MODE_DISABLED

# --- DETECCIÓN DE ENTRADA (H) ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cambiar_personaje"):
		cambiar_mundo_por_personaje()

func cambiar_mundo_por_personaje() -> void:
	var path_escena : String = ""
	if player == elizabeth:
		path_escena = "res://Levels/Area01/02.tscn"
	elif player == michael:
		path_escena = "res://Levels/Dungeon01/02.tscn"
	
	if path_escena != "":
		
		# Buscamos el LevelManager en el root
		var lm = get_node_or_null("/root/GlobalLevelManager")
		if not lm: lm = get_node_or_null("/root/LevelManager")
		
		if lm:
			lm.load_new_level(path_escena, "", Vector2.ZERO)

# --- 3. FUNCIONES QUE TUS OTROS SCRIPTS PIDEN (Crucial) ---

# Esta es la que te daba el error ahora
func unparent_player( _p : Node2D ) -> void:
	if not is_instance_valid(_p): return
	if is_instance_valid(elizabeth) and elizabeth.get_parent() == _p: 
		_p.remove_child(elizabeth)
	if is_instance_valid(michael) and michael.get_parent() == _p: 
		_p.remove_child(michael)

# Esta la pide el sistema de diálogos
func force_player_reset() -> void:
	if not is_instance_valid(player): return
	var sm = player.get_node_or_null("StateMachine")
	if sm:
		for state in sm.get_children():
			if "idle" in state.name.to_lower():
				sm.change_state(state)
				break
	var anim = player.get_node_or_null("AnimationPlayer")
	if anim:
		if anim.has_animation("idle_down"): anim.play("idle_down")
		anim.advance(0)

# --- 4. GESTIÓN DE POSICIÓN Y ESCENA ---
func set_player_position(_new_pos: Vector2) -> void:
	if is_instance_valid(elizabeth) and is_instance_valid(michael):
		elizabeth.global_position = _new_pos
		michael.global_position = _new_pos
		if is_instance_valid(player):
			player.visible = true
			player.process_mode = Node.PROCESS_MODE_INHERIT
			player_spawned = true
			reset_camera_on_player()

func set_as_parent( _p : Node2D ) -> void:
	if not is_instance_valid(_p): return
	if is_instance_valid(elizabeth):
		if elizabeth.get_parent(): elizabeth.get_parent().remove_child(elizabeth)
		_p.add_child(elizabeth)
	if is_instance_valid(michael):
		if michael.get_parent(): michael.get_parent().remove_child(michael)
		_p.add_child(michael)

func reset_camera_on_player( _duration : float = 0.0 ) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera) and is_instance_valid(player):
		if camera.get_parent(): camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()

# 5. SALUD Y UTILIDADES
func set_health( hp: int, max_hp: int ) -> void:
	if is_instance_valid(player):
		player.max_hp = max_hp
		player.hp = hp
		if player == elizabeth and is_instance_valid(michael): michael.hp = hp
		elif player == michael and is_instance_valid(elizabeth): elizabeth.hp = hp

func shake_camera( trauma : float = 1 ) -> void:
	camera_shook.emit( clampi( trauma, 0, 3 ) )
