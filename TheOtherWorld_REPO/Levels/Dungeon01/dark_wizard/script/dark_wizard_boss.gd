class_name DarkWizardBoss extends Node2D

# --- PRECARGAS DE ESCENAS ---
const ENERGY_EXPLOSION_SCENE : PackedScene = preload( "res://Levels/Dungeon01/dark_wizard/energy_explosion.tscn" )
const ENERGY_BALL_SCENE : PackedScene = preload( "res://Levels/Dungeon01/dark_wizard/energy_orb.tscn" )

# --- ESTADÍSTICAS ---
@export var max_hp : int = 10
var hp : int = 10

# --- AUDIOS ---
var audio_hurt : AudioStream = preload("res://Levels/Dungeon01/dark_wizard/audio/boss_hurt.wav")
var audio_shoot : AudioStream = preload("res://Levels/Dungeon01/dark_wizard/audio/boss_fireball.wav")

# --- VARIABLES DE CONTROL ---
var current_position : int = 0
var positions : Array[ Vector2 ]
var beam_attacks : Array[ BeamAttack ]
var damage_count : int = 0

# --- NODOS ---
@onready var animation_player: AnimationPlayer = $BossNode/AnimationPlayer
@onready var animation_player_damaged: AnimationPlayer = $BossNode/AnimationPlayer_Damaged
@onready var cloak_animation_player: AnimationPlayer = $BossNode/CloakSprite/AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $BossNode/AudioStreamPlayer2D
@onready var boss_node: Node2D = $BossNode
@onready var persistent_data_handler: PersistentDataHandler = $PersistentDataHandler
@onready var hurt_box: HurtBox = $BossNode/HurtBox
@onready var hit_box: HitBox = $BossNode/HitBox
@onready var door_block: TileMapLayer = $"../DoorBlock"

# --- SPRITES (MANOS) ---
@onready var hand_01: Sprite2D = $BossNode/CloakSprite/Hand01
@onready var hand_02: Sprite2D = $BossNode/CloakSprite/Hand02
@onready var hand_01_up: Sprite2D = $BossNode/CloakSprite/Hand01_UP
@onready var hand_02_up: Sprite2D = $BossNode/CloakSprite/Hand02_UP
@onready var hand_01_side: Sprite2D = $BossNode/CloakSprite/Hand01_SIDE
@onready var hand_02_side: Sprite2D = $BossNode/CloakSprite/Hand02_SIDE

func _ready() -> void:
	# Verificamos si ya fue derrotado anteriormente
	persistent_data_handler.get_value()
	if persistent_data_handler.value == true:
		if is_instance_valid(door_block):
			door_block.enabled = false
		queue_free()
		return
	
	hp = max_hp
	PlayerHud.show_boss_health( "Dark Wizard" )
	
	# Conexión segura de la señal de daño
	if hit_box.has_signal("damaged"):
		hit_box.damaged.connect( damage_taken )
	
	# Configurar posiciones de teletransporte
	for c in $PositionTargets.get_children():
		positions.append( c.global_position )
	$PositionTargets.visible = false
	
	# Configurar ataques de rayo
	for b in $BeamAttacks.get_children():
		beam_attacks.append( b )
	
	teleport( 0 )

func _process(_delta: float) -> void:
	# Sincronización de frames de las manos para las animaciones
	hand_01_up.position = hand_01.position
	hand_01_up.frame = hand_01.frame + 4
	hand_02_up.position = hand_02.position
	hand_02_up.frame = hand_02.frame + 4
	hand_01_side.position = hand_01.position
	hand_01_side.frame = hand_01.frame + 8
	hand_02_side.position = hand_02.position
	hand_02_side.frame = hand_02.frame + 12

func teleport( _location : int ) -> void:
	animation_player.play( "disappear" )
	enable_hit_boxes( false )
	damage_count = 0
	
	if hp < max_hp:
		shoot_orb()
	
	await get_tree().create_timer( 1 ).timeout
	
	if is_instance_valid(boss_node):
		boss_node.global_position = positions[ _location ]
		current_position = _location
		update_animations()
		animation_player.play( "appear" )
		await animation_player.animation_finished
		idle()

func idle() -> void:
	enable_hit_boxes()
	
	if randf() <= float(hp) / float(max_hp):
		animation_player.play( "idle" )
		await animation_player.animation_finished
		if hp < 1: return
	
	if damage_count < 1:
		energy_beam_attack()
		animation_player.play( "cast_spell" )
		await animation_player.animation_finished
	
	if hp < 1: return
	
	var _t : int = current_position
	while _t == current_position:
		_t = randi_range( 0, 3 )
	teleport( _t )

func update_animations() -> void:
	boss_node.scale = Vector2( 1, 1 )
	
	# Ocultar todas las manos antes de activar la correcta
	var hands = [hand_01, hand_02, hand_01_up, hand_02_up, hand_01_side, hand_02_side]
	for h in hands: h.visible = false
	
	if current_position == 0:
		cloak_animation_player.play( "down" )
		hand_01.visible = true
		hand_02.visible = true
	elif current_position == 2:
		cloak_animation_player.play( "up" )
		hand_01_up.visible = true
		hand_02_up.visible = true
	else:
		cloak_animation_player.play( "side" )
		hand_01_side.visible = true
		hand_02_side.visible = true
		if current_position == 1:
			boss_node.scale = Vector2( -1, 1 )

func energy_beam_attack() -> void:
	var _b : Array[ int ]
	match current_position:
		0, 2:
			_b.append( 0 if current_position == 0 else 2 )
			_b.append( randi_range( 1, 2 ) if current_position == 0 else randi_range( 0, 1 ) )
			if hp < 5: _b.append( randi_range( 3, 5 ) )
		1, 3:
			_b.append( 5 if current_position == 3 else 3 )
			_b.append( randi_range( 3, 4 ) if current_position == 3 else randi_range( 4, 5 ) )
			if hp < 5: _b.append( randi_range( 0, 2 ) )
	for b in _b:
		if b < beam_attacks.size():
			beam_attacks[ b ].attack()

func shoot_orb() -> void:
	var eb : Node2D = ENERGY_BALL_SCENE.instantiate()
	eb.global_position = boss_node.global_position + Vector2( 0, -34 )
	get_parent().add_child.call_deferred( eb )
	play_audio( audio_shoot )

func damage_taken( _hurt_box : HurtBox ) -> void:
	if animation_player_damaged.current_animation == "damaged" or _hurt_box.damage == 0:
		return
	play_audio( audio_hurt )
	hp = clampi( hp - _hurt_box.damage, 0, max_hp )
	damage_count += 1
	PlayerHud.update_boss_health( hp, max_hp )
	animation_player_damaged.play( "damaged" )
	animation_player_damaged.seek( 0 )
	animation_player_damaged.queue( "default" )
	
	if hp < 1:
		defeat()

func play_audio( _a : AudioStream ) -> void:
	if is_instance_valid(audio):
		audio.stream = _a
		audio.play()

func defeat() -> void:
	# Detenemos procesos para evitar errores de memoria mientras muere
	set_process(false)
	enable_hit_boxes( false )
	
	animation_player.play( "destroy" )
	PlayerHud.hide_boss_health()
	
	await animation_player.animation_finished
	
	# Soltamos la flauta
	if has_node("ItemDropper"):
		$ItemDropper.position = boss_node.position
		$ItemDropper.drop_item()
		# Al recoger la flauta se llama a open_dungeon (la salida)
		$ItemDropper.drop_collected.connect( open_dungeon )

func open_dungeon() -> void:
	# Guardar que el jefe murió para siempre
	persistent_data_handler.set_value()
	
	if is_instance_valid(door_block):
		door_block.enabled = false
	
	# SALIDA SEGURA: Esperamos al final del frame para no romper el GlobalPlayerManager
	get_tree().call_deferred("change_scene_to_file", "res://title_scene/title_scene.tscn")

func enable_hit_boxes( _v : bool = true ) -> void:
	if is_instance_valid(hit_box): hit_box.set_deferred( "monitorable", _v )
	if is_instance_valid(hurt_box): hurt_box.set_deferred( "monitoring", _v )

func explosion( _p : Vector2 = Vector2.ZERO ) -> void:
	var e : Node2D = ENERGY_EXPLOSION_SCENE.instantiate()
	e.global_position = boss_node.global_position + _p
	get_parent().add_child.call_deferred( e )
