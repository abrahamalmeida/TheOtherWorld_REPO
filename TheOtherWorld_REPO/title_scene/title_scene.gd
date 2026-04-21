extends Node2D

const INTRO_STORY_SCENE : String = "res://historia_inicial.tscn" 
const CREDITS_SCENE : String = "res://Creditos.tscn"

@export var music : AudioStream
@export var button_focus_audio : AudioStream
@export var button_press_audio : AudioStream

@onready var button_new: Button = $CanvasLayer/Control/ButtonNew
@onready var button_credits: Button = $CanvasLayer/Control/Buttoncredits
@onready var button_end: Button = $CanvasLayer/Control/Buttonend
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# El menú de inicio debe poder procesarse siempre
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	
	if PlayerManager.player:
		PlayerManager.player.visible = false
	
	PlayerHud.visible = false
	
	# --- CORRECCIÓN CLAVE ---
	if PlayerManager.pause_menu_instance:
		PlayerManager.pause_menu_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	if has_node("CanvasLayer/SplashScene"):
		$CanvasLayer/SplashScene.finished.connect( setup_title_screen )
	else:
		setup_title_screen()
		
	LevelManager.level_load_started.connect( exit_title_screen )

func setup_title_screen() -> void:
	AudioManager.play_music( music )
	
	# Conexiones
	button_new.pressed.connect( start_game )
	button_credits.pressed.connect( show_credits )
	button_end.pressed.connect( quit_game )
	
	button_new.grab_focus()
	
	button_new.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	button_credits.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	button_end.focus_entered.connect( play_audio.bind( button_focus_audio ) )

func start_game() -> void:
	play_audio( button_press_audio )
	get_tree().paused = false 
	get_tree().change_scene_to_file( INTRO_STORY_SCENE )

func show_credits() -> void:
	play_audio( button_press_audio )
	get_tree().paused = false
	get_tree().change_scene_to_file( CREDITS_SCENE )

func quit_game() -> void:
	play_audio( button_press_audio )
	print("Saliendo...")
	# 'true' en create_timer permite que funcione aunque esté pausado
	await get_tree().create_timer(0.2, true, false, true).timeout
	get_tree().quit()

func exit_title_screen() -> void:
	if PlayerManager.player:
		PlayerManager.player.visible = true
	
	PlayerHud.visible = true
	
	# --- CORRECCIÓN CLAVE ---
	if PlayerManager.pause_menu_instance:
		PlayerManager.pause_menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
		
	self.queue_free()

func play_audio( _a : AudioStream ) -> void:
	if _a and is_instance_valid(audio_stream_player):
		audio_stream_player.stream = _a
		audio_stream_player.play()
