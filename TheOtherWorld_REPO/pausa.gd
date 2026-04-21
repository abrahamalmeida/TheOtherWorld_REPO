extends Node2D

# --- REFERENCIAS ---
# No necesitamos @onready para los botones si solo usamos señales, 
# pero los definimos por si quieres cambiarles el texto por código.
@onready var resume_btn = $ColorRect/CenterContainer/VBoxContainer/ResumeBtn
@onready var quit_btn = $ColorRect/CenterContainer/VBoxContainer/QuitBtn

func _ready() -> void:
	# El menú debe estar oculto al iniciar el nivel
	visible = false
	
	# PASO VITAL: Configura el modo de proceso por código para estar seguros
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Si presionas Escape (ui_cancel)
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var pausar = !get_tree().paused
	get_tree().paused = pausar
	visible = pausar
	
	if pausar:
		print("Juego pausado")
	else:
		print("Juego reanudado")

# --- SEÑALES (Conéctalas en la pestaña 'Nodo' del editor) ---

func _on_resume_btn_pressed() -> void:
	toggle_pause()

func _on_quit_btn_pressed() -> void:
	# Quitar pausa antes de salir para evitar bugs en el menú
	get_tree().paused = false
	
	# Si quieres ir al menú principal:
	if is_instance_valid(LevelManager):
		LevelManager.load_new_level("res://title_scene/title_scene.tscn", "", Vector2.ZERO)
	else:
		# Si solo quieres cerrar el juego:
		get_tree().quit()
