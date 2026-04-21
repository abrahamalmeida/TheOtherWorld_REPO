extends CanvasLayer

signal shown
signal hidden

@onready var tab_container: TabContainer = $Control/TabContainer
# Ruta exacta de tu imagen: Control -> TabContainer -> Pausa -> VBoxContainer -> Button_Quit
@onready var button_quit: Button = get_node_or_null("Control/TabContainer/Pausa/VBoxContainer/Button_Quit")

var is_paused : bool = false

func _ready() -> void:
	# Permitir que el menú funcione mientras el resto está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Empezar oculto
	hide_pause_menu()
	
	# Conexión del botón de salir
	if is_instance_valid(button_quit):
		button_quit.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	# Detectar la tecla P física para pausar/despausar
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		# Detener el input para que no afecte a otros scripts (como el de Michael)
		get_viewport().set_input_as_handled()
		
		if not is_paused:
			show_pause_menu()
		else:
			hide_pause_menu()

func show_pause_menu() -> void:
	is_paused = true
	get_tree().paused = true # Congela el juego
	visible = true
	shown.emit()
	if is_instance_valid(tab_container):
		tab_container.current_tab = 0

func hide_pause_menu() -> void:
	is_paused = false
	get_tree().paused = false # Reanuda el juego
	visible = false
	hidden.emit()

func _on_quit_pressed() -> void:
	# Quitar pausa antes de salir para que la siguiente escena no esté congelada
	get_tree().paused = false
	
	# Ajusta esta ruta a la de tu menú de inicio
	var ruta_titulo = "res://title_scene/title_scene.tscn"
	
	if is_instance_valid(LevelManager):
		LevelManager.load_new_level(ruta_titulo, "", Vector2.ZERO)
	else:
		get_tree().change_scene_to_file(ruta_titulo)

# --- EVITAR ERRORES EXTERNOS ---
# Estas funciones se quedan vacías para que el resto del juego 
# no crashee al buscarlas (habilidades, inventario, etc.)
func update_ability_items(_items): pass
func focused_item_changed(_slot): pass
func update_item_description(_text): pass
func preview_stats(_item): pass
