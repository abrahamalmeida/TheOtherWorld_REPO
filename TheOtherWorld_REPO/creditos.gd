extends Control

# Velocidad de desplazamiento (píxeles por segundo)
@export var scroll_speed : int = 150
@onready var container = $ScrollContainer/VBoxContainer

func _ready():
	# Colocamos el texto justo debajo del borde inferior de la pantalla al empezar
	container.global_position.y = get_viewport_rect().size.y

func _process(delta):
	# Movemos el contenedor hacia arriba
	container.position.y -= scroll_speed * delta
	
	# Si el texto ya salió por completo de la pantalla, volvemos al menú
	# Ajusta el valor ( -1000 ) dependiendo de qué tan largo sea tu texto
	if container.position.y < -container.size.y:
		exit_credits()

func _input(event):
	# Si el jugador presiona "Esc" o "Aceptar", sale de los créditos
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		exit_credits()

func exit_credits():
	# Cambia "res://main_menu.tscn" por la ruta de tu escena de título
	get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")
