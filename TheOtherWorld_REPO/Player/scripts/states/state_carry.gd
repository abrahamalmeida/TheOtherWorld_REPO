class_name State_Carry extends State

@export var move_speed : float = 100.0
@export var throw_audio : AudioStream

var walking : bool = false
var throwable : Throwable

# Cambiamos a State genérico para evitar errores de tipado si el nodo no está listo
@onready var idle: State = $"../Idle"
@onready var stun: State = $"../Stun"

## What happens when we initialize this state?
func init() -> void:
	pass

## What happens when the player enters this State?
func enter() -> void:
	player.update_animation( "carry" )
	walking = false

## What happens when the player exits this State?
func exit() -> void:
	# Verificamos que el objeto aún exista antes de intentar lanzarlo
	if is_instance_valid(throwable):
		if player.direction == Vector2.ZERO:
			throwable.throw_direction = player.cardinal_direction
		else:
			throwable.throw_direction = player.direction
		
		# Si salimos de este estado porque nos golpearon (Stun)
		if state_machine.next_state == stun:
			throwable.throw_direction = throwable.throw_direction.rotated( PI )
			throwable.drop()
		else:
			# Solo lanzamos si el personaje está activo (evita lanzamientos fantasmas al cambiar PJ)
			if PlayerManager.player == player:
				player.audio.stream = throw_audio
				player.audio.play()
				throwable.throw()
			else:
				# Si el personaje se desactivó por el intercambio, simplemente soltamos el objeto
				throwable.drop()
	
	# Limpiamos la referencia para evitar errores de memoria
	throwable = null

## What happens during the _process update in this State?
func process( _delta : float ) -> State:
	# Si por alguna razón el objeto se rompe o desaparece, volvemos a Idle
	if not is_instance_valid(throwable):
		return idle

	if player.direction == Vector2.ZERO:
		if walking == true:
			walking = false
			player.update_animation( "carry" )
	elif player.set_direction() or walking == false:
		player.update_animation( "carry_walk" )
		walking = true
	
	player.velocity = player.direction * move_speed
	return null

## What happens during the _physics_process update in this State?
func physics( _delta : float ) -> State:
	return null

## What happens with input events in this State?
func handle_input( _event: InputEvent ) -> State:
	if _event.is_action_pressed("attack") or _event.is_action_pressed("interact"):
		return idle
	return null
