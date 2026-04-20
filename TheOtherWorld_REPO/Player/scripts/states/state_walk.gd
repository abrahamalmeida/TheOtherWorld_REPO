class_name State_Walk extends State

@export var move_speed : float = 100.0

@onready var idle : State = $"../Idle"
@onready var attack : State = $"../Attack"
@onready var dash : State = $"../Dash"

## Al entrar al estado
func enter() -> void:
	player.update_animation("walk")

## Al salir del estado
func exit() -> void:
	pass

## Actualización lógica
func process( _delta : float ) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	
	player.velocity = player.direction * move_speed
	
	if player.set_direction():
		player.update_animation("walk")
	return null

## Actualización física
func physics( _delta : float ) -> State:
	return null

## Manejo de Input (CORREGIDO)
func handle_input( _event: InputEvent ) -> State:
	# Seguridad: Solo el personaje activo procesa input
	if PlayerManager.player != player:
		return null

	if _event.is_action_pressed("attack"):
		return attack
	elif _event.is_action_pressed("interact"):
		# Evitamos el crash verificando que la función exista
		if PlayerManager.has_method("interact"):
			PlayerManager.interact()
	elif _event.is_action_pressed("dash"):
		return dash
	return null
