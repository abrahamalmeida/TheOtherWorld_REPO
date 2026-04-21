extends CanvasLayer

# Intentamos agarrar el botón por la ruta que me diste
@onready var quit_button = get_node_or_null("Control/TabContainer/Pausa/VBoxContainer/Button_Quit")

func _ready() -> void:
	# 1. ESTO ES LO MÁS IMPORTANTE DEL MUNDO
	process_mode = Node.PROCESS_MODE_ALWAYS 
	visible = false
	
	# 2. Conexión manual del botón de cerrar
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	else:
		# Si la ruta falló, buscamos el botón por nombre en todo el menú
		_find_quit_button_recursively(self)

func _unhandled_input(event: InputEvent) -> void:
	# Si presionas ESC y el menú está visible, lo cerramos y despausamos
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause_menu() -> void:
	get_tree().paused = true # Pausa el juego
	visible = true           # Muestra la capa
	if quit_button:
		quit_button.grab_focus()

func hide_pause_menu() -> void:
	get_tree().paused = false # ¡QUITA LA PAUSA!
	visible = false          # Esconde la capa

func _on_quit_button_pressed() -> void:
	print("Botón presionado: Cerrando juego...")
	get_tree().quit()

# Función extra por si acaso la ruta del botón cambió sin querer
func _find_quit_button_recursively(node: Node):
	for child in node.get_children():
		if child is Button and (child.name == "Button_Quit" or child.name == "Button_end"):
			quit_button = child
			if not quit_button.pressed.is_connected(_on_quit_button_pressed):
				quit_button.pressed.connect(_on_quit_button_pressed)
			return
		_find_quit_button_recursively(child)
