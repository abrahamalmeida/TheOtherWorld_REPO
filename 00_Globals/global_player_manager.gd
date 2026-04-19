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
	# Instanciamos inmediatamente para evitar errores de Nil en otros scripts
	elizabeth = PLAYER.instantiate()
	michael = MICHAEL_SCENE.instantiate()
	
	player = elizabeth
	
	add_child(elizabeth)
	add_child(michael)
	
	elizabeth.visible = false
	elizabeth.process_mode = Node.PROCESS_MODE_DISABLED
	michael.visible = false
	michael.process_mode = Node.PROCESS_MODE_DISABLED

# 3. FUNCIÓN DE SPAWN
func set_player_position(_new_pos: Vector2) -> void:
	# Verificamos que los personajes existan antes de moverlos
	if is_instance_valid(elizabeth) and is_instance_valid(michael):
		elizabeth.global_position = _new_pos
		michael.global_position = _new_pos
		
		if is_instance_valid(player):
			player.visible = true
			player.process_mode = Node.PROCESS_MODE_INHERIT
			player_spawned = true
			reset_camera_on_player()

# 4. GESTIÓN DE SALUD Y XP (Blindada)
func set_health( hp: int, max_hp: int ) -> void:
	if is_instance_valid(player):
		player.max_hp = max_hp
		player.hp = hp
		player.update_hp( 0 )
		
		# Sincronización segura con el otro personaje
		if player == elizabeth and is_instance_valid(michael):
			michael.hp = hp
		elif player == michael and is_instance_valid(elizabeth):
			elizabeth.hp = hp

func reward_xp( _xp : int ) -> void:
	if is_instance_valid(player):
		player.xp += _xp
		check_for_level_advance()

func check_for_level_advance() -> void:
	if not is_instance_valid(player) or player.level >= level_requirements.size(): 
		return
	if player.xp >= level_requirements[ player.level ]:
		player.level += 1
		player.attack += 1
		player.defense += 1
		player_leveled_up.emit()
		check_for_level_advance()

# 5. GESTIÓN DE ESCENA Y CÁMARA (Anti-Crashes)
func set_as_parent( _p : Node2D ) -> void:
	if not is_instance_valid(_p) or not is_instance_valid(player): 
		return
		
	# Movemos a AMBOS de forma segura
	if is_instance_valid(elizabeth):
		if elizabeth.get_parent(): elizabeth.get_parent().remove_child(elizabeth)
		_p.add_child(elizabeth)
		
	if is_instance_valid(michael):
		if michael.get_parent(): michael.get_parent().remove_child(michael)
		_p.add_child(michael)

func reset_camera_on_player( _duration : float = 0.0 ) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	
	if is_instance_valid(camera) and is_instance_valid(player):
		var smoothing_was_enabled = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false
		
		if camera.get_parent():
			camera.get_parent().remove_child(camera)
		
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()
		
		await get_tree().process_frame
		if is_instance_valid(camera): # Re-verificamos después del await
			camera.position_smoothing_enabled = smoothing_was_enabled

# 6. UTILIDADES
func play_audio( _audio : AudioStream ) -> void:
	if is_instance_valid(player) and player.has_node("AudioStreamPlayer2D"):
		player.audio.stream = _audio
		player.audio.play()

func interact() -> void:
	if is_instance_valid(player):
		interact_handled = false
		interact_pressed.emit()

func shake_camera( trauma : float = 1 ) -> void:
	camera_shook.emit( clampi( trauma, 0, 3 ) )

func unparent_player( _p : Node2D ) -> void:
	if not is_instance_valid(_p): return
	if is_instance_valid(elizabeth) and elizabeth.get_parent() == _p: 
		_p.remove_child(elizabeth)
	if is_instance_valid(michael) and michael.get_parent() == _p: 
		_p.remove_child(michael)

func force_player_reset() -> void:
	if not is_instance_valid(player): return
	
	# 1. Resetear la StateMachine al estado Idle
	var sm = player.get_node_or_null("StateMachine")
	if sm:
		for state in sm.get_children():
			if "idle" in state.name.to_lower():
				sm.change_state(state)
				break

	# 2. Desbloquear animaciones
	var anim = player.get_node_or_null("AnimationPlayer")
	if anim:
		anim.play("idle_down")
		anim.advance(0)

	# 3. Limpiar el Boomerang/Tirachinas (MUY IMPORTANTE)
	if player.has_node("Abilities"):
		var ab = player.get_node("Abilities")
		if "boomerang_instance" in ab:
			ab.boomerang_instance = null

	# 4. Borrar estelas del Dash del nivel
	var level = player.get_parent()
	if level:
		for child in level.get_children():
			if "ghost" in child.name.to_lower() or "trail" in child.name.to_lower():
				child.queue_free()
