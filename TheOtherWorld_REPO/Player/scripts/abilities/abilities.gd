class_name PlayerAbilities extends Node

# Rutas
const BOOMERANG = preload("res://Player/boomerang.tscn")
const STONE_PROJECTILE = preload("res://Interactables/arrow/arrow.tscn") 

var abilities : Array[ String ] = [
	"", "", "", "" 
]

var selected_ability : int = 0
var boomerang_instance : Boomerang = null

@onready var state_machine: PlayerStateMachine = $"../StateMachine"
@onready var idle: State_Idle = $"../StateMachine/Idle"
@onready var walk: State_Walk = $"../StateMachine/Walk"
@onready var bow: State_Bow = $"../StateMachine/Bow" 

func _ready() -> void:
	if PlayerManager.player:
		PlayerHud.update_arrow_count( PlayerManager.player.arrow_count )
	
	setup_abilities()
	SaveManager.game_loaded.connect( _on_game_loaded )
	PlayerManager.INVENTORY_DATA.ability_acquired.connect( _on_ability_acquired )

func setup_abilities( select_index : int = 0 ) -> void:
	PauseMenu.update_ability_items( abilities )
	PlayerHud.update_ability_items( abilities )
	selected_ability = select_index - 1
	toggle_ability()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "ability" ):
		match selected_ability:
			0:
				boomerang_ability()
			2:
				slingshot_ability() 
	elif event.is_action_pressed("switch_ability"):
		toggle_ability()

func toggle_ability() -> void:
	if abilities.count( "" ) == abilities.size():
		return
	selected_ability = wrapi( selected_ability + 1, 0, 4 )
	while abilities[ selected_ability ] == "":
		selected_ability = wrapi( selected_ability + 1, 0, 4 )
	PlayerHud.update_ability_ui( selected_ability )

func boomerang_ability() -> void:
	if is_instance_valid(boomerang_instance):
		return
	
	var p = PlayerManager.player
	var _b = BOOMERANG.instantiate() as Boomerang
	
	p.add_sibling( _b )
	_b.global_position = p.global_position
	
	var throw_direction = p.direction
	if throw_direction == Vector2.ZERO:
		throw_direction = p.cardinal_direction
	
	_b.throw( throw_direction )
	boomerang_instance = _b

func slingshot_ability() -> void:
	var p = PlayerManager.player
	
	if p.arrow_count <= 0:
		return
	
	if state_machine.current_state == idle or state_machine.current_state == walk:
		p.arrow_count -= 1
		PlayerHud.update_arrow_count( p.arrow_count )
		state_machine.change_state( bow )

func clean_abilities() -> void:
	if is_instance_valid(boomerang_instance):
		boomerang_instance.queue_free()
	boomerang_instance = null

func _on_game_loaded() -> void:
	var new_abilities = SaveManager.current_save.abilities
	abilities.clear()
	for i in new_abilities:
		if i == "GRAPPLE" or i == "BOMB":
			abilities.append("")
		else:
			abilities.append( i )
	setup_abilities()

func _on_ability_acquired( _ability : AbilityItemData ) -> void:
	match _ability.type:
		_ability.Type.BOOMERANG:
			abilities[0] = "BOOMERANG"
		_ability.Type.ARROW:
			abilities[2] = "SLINGSHOT"
	setup_abilities( selected_ability )
