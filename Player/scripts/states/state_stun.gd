extends State
class_name State_Stun

@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0
@export var invulnerable_duration : float = 1.0

var direction : Vector2
var next_state : State = null
var hurt_box : HurtBox 

@onready var idle : State = $"../Idle"
@onready var death: State = $"../Death"

func init() -> void:
	player.player_damaged.connect( _player_damaged )

func enter() -> void:
	if not hurt_box:
		next_state = idle
		return
		
	if not player.animation_player.animation_finished.is_connected(_animation_finished):
		player.animation_player.animation_finished.connect( _animation_finished )
	
	direction = player.global_position.direction_to( hurt_box.global_position )
	player.velocity = direction * -knockback_speed
	player.set_direction()
	
	player.update_animation("stun")
	player.make_invulnerable( invulnerable_duration )
	player.effect_animation_player.play("damaged")
	
	if PlayerManager:
		PlayerManager.shake_camera( hurt_box.damage )

func exit() -> void:
	next_state = null
	if player.animation_player.animation_finished.is_connected(_animation_finished):
		player.animation_player.animation_finished.disconnect( _animation_finished )

func process( _delta : float ) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	return next_state

func _player_damaged( _hurt_box : HurtBox ) -> void:
	if PlayerManager.player != player: return
	
	hurt_box = _hurt_box
	if state_machine.current_state != death:
		state_machine.change_state( self )

func _animation_finished( _a: String ) -> void:
	if player.hp <= 0:
		next_state = death
	else:
		next_state = idle
