extends CanvasLayer

signal shown
signal hidden

@onready var tab_container: TabContainer = $Control/TabContainer
@onready var button_quit: Button = get_node_or_null("Control/TabContainer/Pausa/VBoxContainer/Button_Quit")

var is_paused : bool = false

func _ready() -> void:
	# Crucial para que funcione mientras el juego está congelado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Asegurarnos de que el CanvasLayer sea la capa más alta
	layer = 100 
	
	hide_pause_menu()
	print("--- PAUSE MENU: Cargado en el árbol de escenas ---")
	
	if is_instance_valid(button_quit):
		if not button_quit.pressed.is_connected(_on_quit_pressed):
			button_quit.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	# Detectamos ESC o P para descartar fallos de teclas
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			print("--- PAUSE MENU: Tecla detectada correctamente ---")
			get_viewport().set_input_as_handled()
			toggle_pause()

func toggle_pause() -> void:
	if not is_paused:
		show_pause_menu()
	else:
		hide_pause_menu()

func show_pause_menu() -> void:
	is_paused = true
	self.visible = true
	get_tree().paused = true 
	shown.emit()
	if is_instance_valid(tab_container):
		tab_container.current_tab = 0
	print("--- PAUSE MENU: Juego Pausado ---")

func hide_pause_menu() -> void:
	is_paused = false
	self.visible = false
	get_tree().paused = false 
	hidden.emit()
	print("--- PAUSE MENU: Juego Reanudado ---")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	var ruta_titulo = "res://title_scene/title_scene.tscn"
	if is_instance_valid(LevelManager):
		LevelManager.load_new_level(ruta_titulo, "", Vector2.ZERO)
	else:
		get_tree().change_scene_to_file(ruta_titulo)

# STUBS
func update_ability_items(_items): pass
func focused_item_changed(_slot): pass
func update_item_description(_text): pass
func preview_stats(_item): pass
