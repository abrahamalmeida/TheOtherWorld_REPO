class_name State_Dash extends State

@export var move_speed : float = 200.0
@export var effect_delay : float = 0.1
@export var dash_audio : AudioStream

@onready var idle: State = $"../Idle"

var direction : Vector2 = Vector2.ZERO
var next_state : State = null
var effect_timer : float = 0

## What happens when the player enters this State?
func enter() -> void:
	player.invulnerable = true
	player.update_animation( "dash" )
	
	# Conexión segura
	if not player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.connect( _on_animation_finished )
	
	direction = player.direction
	if direction == Vector2.ZERO:
		# Si no hay dirección, dasheamos hacia donde mira, no hacia atrás
		direction = player.cardinal_direction
	
	if dash_audio:
		player.audio.stream = dash_audio
		player.audio.play()
	
	effect_timer = 0
	next_state = null

## What happens when the player exits this State?
func exit() -> void:
	player.invulnerable = false
	if player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
	
	# Limpiamos la velocidad para que no salga disparado al cambiar de estado
	player.velocity = Vector2.ZERO
	next_state = null

## What happens during the _process update in this State?
func process( _delta : float ) -> State:
	player.velocity = direction * move_speed
	
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		spawn_effect()
	
	return next_state

func _on_animation_finished( _anim_name : String ) -> void:
	next_state = idle

func spawn_effect() -> void:
	# Si el personaje ya no es el activo (por intercambio), dejamos de spawnear estelas
	if PlayerManager.player != player:
		return

	var effect : Node2D = Node2D.new()
	# Añadimos al grupo "trail" para poder borrarlos masivamente si hace falta
	effect.add_to_group("trail")
	
	player.get_parent().add_child( effect )
	effect.global_position = player.global_position
	effect.modulate = Color( 1.5, 0.2, 1.25, 0.75 )
	
	var sprite_copy : Sprite2D = player.sprite.duplicate()
	# Nos aseguramos de que la copia no herede scripts o colisiones
	sprite_copy.process_mode = Node.PROCESS_MODE_DISABLED
	effect.add_child( sprite_copy )
	
	var tween : Tween = create_tween()
	tween.set_ease( Tween.EASE_OUT )
	tween.tween_property( effect, "modulate", Color( 1, 1, 1, 0.0 ), 0.2 )
	tween.tween_callback( effect.queue_free )
