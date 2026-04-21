class_name Player extends CharacterBody2D

# --- SEÑALES ---
signal direction_changed( new_direction: Vector2 )
signal player_damaged( hurt_box: HurtBox )

# --- CONSTANTES ---
const DIR_4 = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]

# --- VARIABLES DE MOVIMIENTO ---
var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

# --- VARIABLES DE ESTADO Y VIDA ---
var invulnerable : bool = false
var hp : int = 12
var max_hp : int = 12

# --- REGENERACIÓN PASIVA ---
var regen_val : int = 1           
var regen_wait_time : float = 2.0   
var regen_timer : Timer           

# --- ESTADÍSTICAS ---
var level : int = 1
var xp : int = 0
var attack : int = 1 :
	set( v ):
		attack = v
		update_damage_values()

var defense : int = 1
var defense_bonus : int = 0

# --- MUNICIÓN ---
var arrow_count : int = 10 : set = _set_arrow_count
var bomb_count : int = 10 : set = _set_bomb_count

# --- NODOS @ONREADY ---
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var effect_animation_player : AnimationPlayer = $EffectAnimationPlayer
@onready var hit_box : HitBox = $HitBox
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayerStateMachine = $StateMachine
@onready var audio: AudioStreamPlayer2D = $Audio/AudioStreamPlayer2D
@onready var lift: State_Lift = $StateMachine/Lift
@onready var held_item: Node2D = $Sprite2D/HeldItem
@onready var carry: State_Carry = $StateMachine/Carry
@onready var player_abilities: PlayerAbilities = $Abilities

# --- FUNCIONES CORE ---

func _ready():
	# --- FIX DE SPAWN: Forzar que Elizabeth sea la activa al cargar/morir ---
	if name == "Elizabeth":
		PlayerManager.player = self
		self.visible = true
		self.process_mode = Node.PROCESS_MODE_INHERIT
		print("DEBUG: Elizabeth ha tomado el mando.")
	elif name == "Michael":
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
		print("DEBUG: Michael esperando en reserva.")

	state_machine.Initialize(self)
	hit_box.damaged.connect( _take_damage )
	update_hp(99)
	update_damage_values()
	
	_setup_regen_timer()
	
	if PlayerManager.player_leveled_up:
		PlayerManager.player_leveled_up.connect( _on_player_leveled_up )
	if PlayerManager.INVENTORY_DATA:
		PlayerManager.INVENTORY_DATA.equipment_changed.connect( _on_equipment_changed )

func _process( _delta ):
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

func _physics_process( _delta ):
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cambiar_personaje"):
		hacer_intercambio()

# --- LÓGICA DE REGENERACIÓN ---

func _setup_regen_timer() -> void:
	regen_timer = Timer.new()
	add_child(regen_timer)
	regen_timer.wait_time = regen_wait_time
	regen_timer.autostart = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	regen_timer.start()

func _on_regen_timer_timeout() -> void:
	if hp > 0 and hp < max_hp:
		update_hp(regen_val)

# --- SISTEMA DE DIRECCIÓN Y ANIMACIÓN ---

func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false
	var direction_id : int = int( round( ( direction + cardinal_direction * 0.1 ).angle() / TAU * DIR_4.size() ) )
	var new_dir = DIR_4[ direction_id ]
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	direction_changed.emit( new_dir )
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func update_animation( state : String ) -> void:
	animation_player.play( state + "_" + anim_direction() )

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

# --- SISTEMA DE COMBATE Y DAÑO ---

func _take_damage( hurt_box : HurtBox ) -> void:
	if invulnerable == true: return
	if hp > 0:
		var dmg : int = hurt_box.damage
		if dmg > 0:
			dmg = clampi( dmg - defense - defense_bonus, 1, dmg )
		update_hp( -dmg )
		player_damaged.emit( hurt_box )

func update_hp( delta : int ) -> void:
	hp = clampi( hp + delta, 0, max_hp )
	PlayerHud.update_hp( hp, max_hp )
	
	# Si llegamos a 0, la StateMachine pasará a State_Death (que ya tienes configurado)
	if hp <= 0:
		state_machine.change_state($StateMachine/Death)

func make_invulnerable( _duration : float = 1.0 ) -> void:
	invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer( _duration ).timeout
	invulnerable = false
	hit_box.monitoring = true

func update_damage_values() -> void:
	if PlayerManager.INVENTORY_DATA:
		var damage_value : int = attack + PlayerManager.INVENTORY_DATA.get_attack_bonus()
		%AttackHurtBox.damage = damage_value
		%ChargeSpinHurtBox.damage = damage_value * 2

# --- INTERACCIONES Y REVIVE ---

func pickup_item( _t : Throwable ) -> void:
	state_machine.change_state( lift )
	carry.throwable = _t

func revive_player() -> void:
	update_hp( 99 )
	state_machine.change_state( $StateMachine/Idle )
	# Al revivir, el fix del _ready se encargará de resetear al jugador si recargas escena

# --- CALLBACKS DE EVENTOS ---

func _on_player_leveled_up() -> void:
	effect_animation_player.play( "level_up" )
	update_hp( max_hp )

func _on_equipment_changed() -> void:
	update_damage_values()
	defense_bonus = PlayerManager.INVENTORY_DATA.get_defense_bonus()

# --- SETTERS DE MUNICIÓN ---

func _set_arrow_count( value : int ) -> void:
	arrow_count = value
	PlayerHud.update_arrow_count( value )

func _set_bomb_count( value : int ) -> void:
	bomb_count = value
	PlayerHud.update_bomb_count( value )

# --- SISTEMA DE INTERCAMBIO (SWAP) ---

func stop_everything() -> void:
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	if state_machine:
		var idle_state = state_machine.get_node_or_null("Idle")
		if idle_state:
			state_machine.change_state(idle_state)
	%AttackHurtBox.monitoring = false
	%ChargeSpinHurtBox.monitoring = false
	animation_player.stop()

func hacer_intercambio() -> void:
	var todos_los_players = get_tree().get_nodes_in_group("players")
	var el_otro = null
	for p in todos_los_players:
		if p != self:
			el_otro = p
			break
			
	if el_otro:
		self.stop_everything()
		var mi_posicion = self.global_position
		
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
		
		el_otro.global_position = mi_posicion
		el_otro.visible = true
		el_otro.process_mode = Node.PROCESS_MODE_INHERIT
		
		if el_otro.has_method("stop_everything"):
			el_otro.stop_everything()

		PlayerManager.player = el_otro
