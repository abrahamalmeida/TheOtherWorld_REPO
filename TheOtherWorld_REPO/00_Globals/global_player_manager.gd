extends Node

# 1. PRECARGAS
const PLAYER = preload("res://Player/player.tscn")
const MICHAEL_SCENE = preload("res://Player/michael.tscn") 
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

# 2. VARIABLES PRIVADAS
var elizabeth : Player
var michael : CharacterBody2D
var ya_viajamos : bool = false        

# 3. EL GETTER MÁGICO: Esto arregla el error de "previously freed"
# Permite que PlayerManager.player funcione fuera, pero con seguridad interna.
var player : CharacterBody2D : 
	get:
		_check_and_instantiate_players()
		var target = michael if ya_viajamos else elizabeth
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			return target
		return null
	set(_v):
		# Bloqueamos la asignación externa para que no nos pasen objetos muertos
		pass

var player_spawned : bool = false
var current_xp : int = 0
var current_level : int = 1
var level_requirements = [ 0, 5, 10, 20, 40, 80, 160 ]

func _ready() -> void:
	_check_and_instantiate_players()
	ya_viajamos = false

func _check_and_instantiate_players() -> void:
	# Verificamos Elizabeth (Doble candado: null + is_instance_valid + is_queued)
	if elizabeth == null or not is_instance_valid(elizabeth) or elizabeth.is_queued_for_deletion():
		elizabeth = PLAYER.instantiate()
		add_child(elizabeth)
		_desactivar_personaje(elizabeth)
		
	# Verificamos Michael
	if michael == null or not is_instance_valid(michael) or michael.is_queued_for_deletion():
		michael = MICHAEL_SCENE.instantiate()
		add_child(michael)
		_desactivar_personaje(michael)

# --- FUNCIONES DE GESTIÓN DE NODOS ---

func set_as_parent(_p: Node2D) -> void:
	if not is_instance_valid(_p) or player == null: return
	if player.get_parent(): 
		player.get_parent().remove_child(player)
	_p.add_child(player)

func unparent_player(_p: Node2D) -> void:
	if not is_instance_valid(_p) or player == null: return
	if player.get_parent() == _p: 
		_p.remove_child(player)
		add_child(player)

func force_player_reset() -> void:
	if player == null: return
	var sm = player.get_node_or_null("StateMachine")
	if is_instance_valid(sm):
		for state in sm.get_children():
			if "idle" in state.name.to_lower():
				sm.change_state(state)
				break

# --- LÓGICA DE JUEGO Y VIAJE ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()

func viaje_unico_a_michael() -> void:
	# Esta línea DEBE tener un Tab al principio
	if ya_viajamos:
		return
	
	ya_viajamos = true
	
	# Todas estas líneas también llevan un Tab
	_check_and_instantiate_players()
	
	if is_instance_valid(elizabeth):
		_desactivar_personaje(elizabeth)
	
	var path_escena : String = "res://Levels/Dungeon01/02.tscn"
	
	if is_instance_valid(LevelManager):
		var spawn_pos = Vector2(250, 250)
		LevelManager.load_new_level(path_escena, "", Vector2.ZERO, spawn_pos)
	else:
		# Fallback por si el Autoload falla
		get_tree().change_scene_to_file(path_escena)

func set_player_position(_new_pos: Vector2) -> void:
	if player == null: return
	
	var scene = get_tree().current_scene
	if is_instance_valid(scene):
		if player.get_parent() != scene:
			if player.get_parent(): player.get_parent().remove_child(player)
			scene.add_child(player)
		
		player.global_position = _new_pos
		_activar_personaje(player)
		player_spawned = true
		reset_camera_on_player()

# --- UTILIDADES ---

func _activar_personaje(node: CharacterBody2D) -> void:
	if is_instance_valid(node) and not node.is_queued_for_deletion():
		node.visible = true
		node.process_mode = Node.PROCESS_MODE_INHERIT

func _desactivar_personaje(node: CharacterBody2D) -> void:
	if is_instance_valid(node) and not node.is_queued_for_deletion():
		node.visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED

func reset_camera_on_player(_duration: float = 0.0) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera) and player != null:
		if camera.get_parent(): camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()

func interact():
	if player != null:
		if player.has_method("player_interact"): player.player_interact()
		elif player.has_method("interact"): player.interact()
		else: interact_pressed.emit()

func set_health(hp: int, max_hp: int) -> void:
	if player != null:
		player.max_hp = max_hp
		player.hp = hp
		var hud = get_node_or_null("/root/PlayerHud")
		if is_instance_valid(hud): hud.update_hp(hp, max_hp)

func reward_xp(amount: int) -> void:
	current_xp += amount
	if current_level < level_requirements.size():
		if current_xp >= level_requirements[current_level]:
			current_level += 1
			player_leveled_up.emit()

func shake_camera(trauma: float = 1) -> void:
	camera_shook.emit(clamp(trauma, 0, 3))
	
func play_audio( _audio_stream : AudioStream ) -> void:
	if _audio_stream == null:
		return
		
	# Creamos un reproductor de audio temporal
	var _audio_player : AudioStreamPlayer = AudioStreamPlayer.new()
	_audio_player.stream = _audio_stream
	_audio_player.bus = "Sound" # Asegúrate de tener un bus llamado "Sound" o usa "Master"
	
	add_child( _audio_player )
	_audio_player.play()
	
	# Lo borramos automáticamente cuando termine de sonar
	_audio_player.finished.connect( _audio_player.queue_free )
