class_name State_Idle extends State

@onready var walk : State = $"../Walk"
@onready var attack : State = $"../Attack"
@onready var dash : State_Dash = $"../Dash"


## Qué sucede cuando el jugador entra en este estado
func enter() -> void:
	player.update_animation("idle")
	player.velocity = Vector2.ZERO


## Qué sucede cuando el jugador sale de este estado
func exit() -> void:
	pass


## Qué sucede durante la actualización _process en este estado
func process( _delta : float ) -> State:
	# Si detectamos movimiento, cambiamos a Walk
	if player.direction != Vector2.ZERO:
		return walk
	
	player.velocity = Vector2.ZERO
	return null


## Qué sucede durante la actualización _physics_process en este estado
func physics( _delta : float ) -> State:
	return null


## Qué sucede con los eventos de entrada en este estado
func handle_input( _event: InputEvent ) -> State:
	# SEGURIDAD: Solo procesar si este personaje es el activo en el PlayerManager
	if PlayerManager.player != player:
		return null

	if _event.is_action_pressed("attack"):
		return attack
	
	elif _event.is_action_pressed("interact"):
		# Verificamos que la función exista en el Manager para evitar el crash
		if PlayerManager.has_method("interact"):
			PlayerManager.interact()
			
	elif _event.is_action_pressed("dash"):
		return dash
		
	return null
