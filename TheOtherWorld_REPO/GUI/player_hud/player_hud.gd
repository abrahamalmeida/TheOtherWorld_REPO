extends CanvasLayer

@export var button_focus_audio : AudioStream = preload( "res://title_scene/audio/menu_focus.wav" )
@export var button_select_audio : AudioStream = preload( "res://title_scene/audio/menu_select.wav" )

var hearts : Array[ HeartGUI ] = []

@onready var game_over : Control = $Control/GameOver
@onready var continue_button: Button = $Control/GameOver/VBoxContainer/ContinueButton
@onready var title_button: Button = $Control/GameOver/VBoxContainer/TitleButton
@onready var animation_player: AnimationPlayer = $Control/GameOver/AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

@onready var abilities: Control = $Control/Abilities
@onready var ability_items: HBoxContainer = $Control/Abilities/HBoxContainer
@onready var arrow_count_label: Label = %ArrowCountLabel
@onready var bomb_count_label: Label = %BombCountLabel

@onready var boss_ui: Control = $Control/BossUI
@onready var boss_hp_bar: TextureProgressBar = $Control/BossUI/TextureProgressBar
@onready var boss_label: Label = $Control/BossUI/Label

@onready var notification_ui : NotificationUI = $Control/Notification

func _ready():
	for child in $Control/HFlowContainer.get_children():
		if child is HeartGUI:
			hearts.append( child )
			child.visible = false
	
	hide_game_over_screen()
	continue_button.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	continue_button.pressed.connect( load_game )
	title_button.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	title_button.pressed.connect( title_screen )
	LevelManager.level_load_started.connect( hide_game_over_screen )
	
	hide_boss_health()
	update_ability_ui( 0 )

	# --- CORRECCIÓN CLAVE PARA LA PAUSA ---
	if PlayerManager.pause_menu_instance:
		PlayerManager.pause_menu_instance.shown.connect( _on_show_pause )
		PlayerManager.pause_menu_instance.hidden.connect( _on_hide_pause )

func update_hp( _hp: int, _max_hp: int ) -> void:
	update_max_hp( _max_hp )
	for i in _max_hp:
		update_heart( i, _hp )

func update_heart( _index : int, _hp : int ) -> void:
	if _index < hearts.size():
		var _value : int = clampi( _hp - _index * 2, 0, 2 )
		hearts[ _index ].value = _value

func update_max_hp( _max_hp : int ) -> void:
	var _heart_count : int = roundi( _max_hp * 0.5 )
	for i in hearts.size():
		if i < _heart_count:
			hearts[i].visible = true
		else:
			hearts[i].visible = false

func show_game_over_screen() -> void:
	game_over.visible = true
	game_over.mouse_filter = Control.MOUSE_FILTER_STOP
	var can_continue : bool = SaveManager.get_save_file() != null
	continue_button.visible = can_continue
	animation_player.play("show_game_over")
	await animation_player.animation_finished
	if can_continue:
		continue_button.grab_focus()
	else:
		title_button.grab_focus()

func hide_game_over_screen() -> void:
	game_over.visible = false
	game_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over.modulate = Color( 1,1,1,0 )

func load_game() -> void:
	play_audio( button_select_audio )
	await fade_to_black()
	SaveManager.load_game()

func title_screen() -> void:
	play_audio( button_select_audio )
	await fade_to_black()
	LevelManager.load_new_level( "res://title_scene/title_scene.tscn", "", Vector2.ZERO )

func fade_to_black() -> bool:
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	if PlayerManager.player:
		PlayerManager.player.revive_player()
	return true

func play_audio( _a : AudioStream ) -> void:
	if is_instance_valid(audio) and _a:
		audio.stream = _a
		audio.play()

func show_boss_health( boss_name : String ) -> void:
	boss_ui.visible = true
	boss_label.text = boss_name
	update_boss_health( 1, 1 )

func hide_boss_health() -> void:
	boss_ui.visible = false

func update_boss_health( hp : int, max_hp : int ) -> void:
	boss_hp_bar.value = clampf( float(hp) / float(max_hp) * 100, 0, 100 )

func queue_notification( _title : String, _message : String ) -> void:
	notification_ui.add_notification_to_queue( _title, _message )

func update_ability_items( items : Array[String] ) -> void:
	var children = ability_items.get_children()
	for i in children.size():
		if i < items.size():
			children[ i ].visible = (items[ i ] != "")

func update_ability_ui( ability_index : int ) -> void:
	var _items : Array[ Node ] = ability_items.get_children()
	if ability_index < _items.size():
		for a in _items:
			a.self_modulate = Color(1,1,1,0)
			a.modulate = Color(0.6,0.6,0.6,0.8)
		_items[ ability_index ].self_modulate = Color(1,1,1,1)
		_items[ ability_index ].modulate = Color(1,1,1,1)
		play_audio( button_focus_audio )

func update_arrow_count( count : int ) -> void:
	arrow_count_label.text = str( count )

func update_bomb_count( count : int ) -> void:
	bomb_count_label.text = str( count )

func _on_show_pause() -> void:
	abilities.visible = false

func _on_hide_pause() -> void:
	abilities.visible = true
