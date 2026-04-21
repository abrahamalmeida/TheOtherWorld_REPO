extends Node2D

@export var michael_scene : PackedScene
var elizabeth_inst : CharacterBody2D
var michael_inst : CharacterBody2D
var personaje_actual : CharacterBody2D

# Bandera para evitar que el cambio se rompa si presionas muy rápido
var cambiando : bool = false

func _ready() -> void:
	visible = false
	# Importante: Re-registramos al player en cada cambio de escena
	elizabeth_inst = PlayerManager.player
	
	if michael_scene:
		michael_inst = michael_scene.instantiate()
		get_parent().call_deferred("add_child", michael_inst)
		michael_inst.visible = false
		michael_inst.process_mode = Node.PROCESS_MODE_DISABLED

	PlayerManager.set_player_position(global_position)
	
	await get_tree().process_frame
	
	# Aseguramos que el Manager sepa quién manda al entrar a la escena
	PlayerManager.player = elizabeth_inst
	PlayerManager.player_spawned = true
	PlayerManager.reset_camera_on_player()
	
	if elizabeth_inst.has_node("StateMachine"):
		elizabeth_inst.get_node("StateMachine").Initialize(elizabeth_inst)
	
	personaje_actual = elizabeth_inst


func cambiar_personaje() -> void:
	var p_manager = PlayerManager
	var p_viejo = p_manager.player
	var p_nuevo = p_manager.michael if p_viejo == p_manager.elizabeth else p_manager.elizabeth
	
	var pos = p_viejo.global_position
	var vida = p_viejo.hp
	
	# 1. Desactivar al viejo
	p_viejo.visible = false
	p_viejo.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Configurar al nuevo
	p_manager.player = p_nuevo
	p_nuevo.global_position = pos
	p_nuevo.hp = vida # Comparten vida
	p_nuevo.visible = true
	p_nuevo.process_mode = Node.PROCESS_MODE_INHERIT
	
	# --- EL TRUCO DE LA CÁMARA ---
	# Esperamos un cuadro para que la posición global se asiente en el motor
	await get_tree().process_frame
	
	# Forzamos a la cámara a actualizarse con el personaje ya posicionado
	p_manager.reset_camera_on_player()
	
	# 3. Inicializar lógica de movimiento
	if p_nuevo.has_node("StateMachine"):
		p_nuevo.get_node("StateMachine").Initialize(p_nuevo)
		
	print("Cambiado a: ", p_nuevo.name)
