extends Node

# --- 1. PRECARGAS ---
const PLAYER = preload("res://Player/player.tscn")
const MICHAEL_SCENE = preload("res://Player/michael.tscn") 
const PAUSE_MENU_SCENE = preload("res://GUI/pause_menu/pause_menu.tscn")
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

# --- 2. SEÑALES ---
signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

# --- 3. VARIABLES DE ESTADO ---
var elizabeth : Player
var michael : CharacterBody2D
var ya_viajamos : bool = false        
var pause_menu_instance : CanvasLayer = null 

var player_spawned : bool = false
var current_xp : int = 0
var current_level : int = 1
var level_requirements = [ 0, 5, 10, 20, 40, 80, 160 ]

# --- 4. GETTER DEL JUGADOR ---
var player : CharacterBody2D : 
	get:
		_check_and_instantiate_players()
		var target = michael if ya_viajamos else elizabeth
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			return target
		return null
	set(_v): pass

# --- 5. INICIALIZACIÓN ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_and_instantiate_players()
	_setup_pause_menu()
	ya_viajamos = false

func _setup_pause_menu() -> void:
	if pause_menu_instance == null:
		pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
		add_child(pause_menu_instance)
		pause_menu_instance.visible = false

# --- 6. LÓGICA DE MICHAEL ---
func viaje_unico_a_michael() -> void:
	if ya_viajamos: return
	ya_viajamos = true
	_check_and_instantiate_players()
	if is_instance_valid(elizabeth): _desactivar_personaje(elizabeth)
	
	var path_escena : String = "res://Levels/Dungeon01/02.tscn"
	if is_instance_valid(LevelManager):
		LevelManager.load_new_level(path_escena, "", Vector2.ZERO, Vector2(250, 250))
	else:
		get_tree().change_scene_to_file(path_escena)

# --- 7. SISTEMA DE XP (EL QUE FALTABA) ---
func reward_xp(amount: int) -> void:
	current_xp += amount
	if current_level < level_requirements.size():
		if current_xp >= level_requirements[current_level]:
			current_level += 1
			player_leveled_up.emit()
			print("¡Subiste de nivel! Nivel actual: ", current_level)

# --- 8. FUNCIONES DE RESET Y CÁMARA ---
func force_player_reset() -> void:
	var p = player
	if is_instance_valid(p):
		p.visible = true
		p.process_mode = Node.PROCESS_MODE_INHERIT
		if p.has_method("revive_player"): p.revive_player()
		if "hp" in p:
			p.hp = p.max_hp
			if is_instance_valid(PlayerHud): PlayerHud.update_hp(p.hp, p.max_hp)

func reset_camera_on_player() -> void:
	var p = player
	if is_instance_valid(p):
		var camera = p.get_node_or_null("Camera2D")
		if is_instance_valid(camera):
			camera.enabled = true
			camera.make_current()

# --- 9. CONTROL DE PAUSA (ESC) ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()

func toggle_pause() -> void:
	if not is_instance_valid(pause_menu_instance): return
	if not get_tree().paused:
		if pause_menu_instance.has_method("show_pause_menu"):
			pause_menu_instance.show_pause_menu()
		else:
			get_tree().paused = true
			pause_menu_instance.visible = true
	else:
		if pause_menu_instance.has_method("hide_pause_menu"):
			pause_menu_instance.hide_pause_menu()
		else:
			get_tree().paused = false
			pause_menu_instance.visible = false

# --- 10. GESTIÓN DE PERSONAJES Y JERARQUÍA ---
func set_player_position(_new_pos: Vector2) -> void:
	if player == null: return
	var scene = get_tree().current_scene
	if is_instance_valid(scene):
		if player.get_parent() != scene:
			if player.get_parent(): player.get_parent().remove_child(player)
			scene.add_child.call_deferred(player)
		player.global_position = _new_pos
		_activar_personaje(player)
		player_spawned = true

func _check_and_instantiate_players() -> void:
	if elizabeth == null or not is_instance_valid(elizabeth):
		elizabeth = PLAYER.instantiate()
		add_child(elizabeth)
		_desactivar_personaje(elizabeth)
	if michael == null or not is_instance_valid(michael):
		michael = MICHAEL_SCENE.instantiate()
		add_child(michael)
		_desactivar_personaje(michael)

func _activar_personaje(node: CharacterBody2D) -> void:
	if is_instance_valid(node):
		node.visible = true
		node.process_mode = Node.PROCESS_MODE_INHERIT

func _desactivar_personaje(node: CharacterBody2D) -> void:
	if is_instance_valid(node):
		node.visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED

func set_as_parent(_p: Node2D) -> void:
	if is_instance_valid(player) and is_instance_valid(_p):
		if player.get_parent(): player.get_parent().remove_child(player)
		_p.add_child(player)

func unparent_player(_p: Node2D) -> void:
	if is_instance_valid(player) and player.get_parent() == _p:
		_p.remove_child(player)

func interact():
	if player != null and player.has_method("player_interact"): player.player_interact()
	else: interact_pressed.emit()

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

func reset_to_default_player() -> void:
	var elizabeth = get_tree().get_first_node_in_group("elizabeth_group") # O como la identifiques
	if elizabeth:
		player = elizabeth
		elizabeth.visible = true
		elizabeth.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Ocultar a Michael si existe
		var michael = get_tree().get_first_node_in_group("michael_group")
		if michael:
			michael.visible = false
			michael.process_mode = Node.PROCESS_MODE_DISABLED
