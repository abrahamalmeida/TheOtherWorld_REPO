extends Node2D

const INTRO_STORY_SCENE : String = "res://historia_inicial.tscn" 

@export var music : AudioStream
@export var button_focus_audio : AudioStream
@export var button_press_audio : AudioStream

@onready var button_new: Button = $CanvasLayer/Control/ButtonNew
@onready var button_continue: Button = $CanvasLayer/Control/ButtonContinue
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# El menú suele pausar el juego, esto está bien aquí
	get_tree().paused = true
	PlayerManager.player.visible = false
	PlayerHud.visible = false
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	
	if SaveManager.get_save_file() == null:
		button_continue.disabled = true
		button_continue.visible = false
	
	# Conexiones de señales
	if has_node("CanvasLayer/SplashScene"):
		$CanvasLayer/SplashScene.finished.connect( setup_title_screen )
	else:
		setup_title_screen()
		
	LevelManager.level_load_started.connect( exit_title_screen )

func setup_title_screen() -> void:
	AudioManager.play_music( music )
	button_new.pressed.connect( start_game )
	button_continue.pressed.connect( load_game )
	button_new.grab_focus()
	
	button_new.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	button_continue.focus_entered.connect( play_audio.bind( button_focus_audio ) )

func start_game() -> void:
	play_audio( button_press_audio )
	print("Iniciando Nuevo Juego... Cargando historia.")
	
	# 1. DESPAUSAR: Crucial para que el script de la historia funcione
	get_tree().paused = false 
	
	# 2. CAMBIAR ESCENA
	var error = get_tree().change_scene_to_file( INTRO_STORY_SCENE )
	if error != OK:
		print("ERROR: No se pudo cargar la escena de la historia. Revisa la ruta: ", INTRO_STORY_SCENE)

func load_game() -> void:
	play_audio( button_press_audio )
	get_tree().paused = false
	SaveManager.load_game()

func exit_title_screen() -> void:
	PlayerManager.player.visible = true
	PlayerHud.visible = true
	PauseMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	self.queue_free()

func play_audio( _a : AudioStream ) -> void:
	if _a:
		audio_stream_player.stream = _a
		audio_stream_player.play()
