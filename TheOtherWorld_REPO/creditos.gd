extends CanvasLayer

@onready var label: RichTextLabel = $ColorRect/RichTextLabel
@onready var color_rect: ColorRect = $ColorRect

# --- AJUSTES DE LOS CRÉDITOS ---
@export var velocidad_subida : float = 35.0  # Píxeles por segundo (suave)
@export var pausa_final : float = 4.0        # Tiempo que se queda el texto al final
@export var margen_seguridad : float = 50.0  # Para que no pegue al borde superior

var creditos_tween : Tween 

func _ready() -> void:
	# Aseguramos que el juego no esté pausado
	get_tree().paused = false 
	
	if not is_instance_valid(label):
		print("Error: No se encontró el RichTextLabel en los créditos")
		return
	
	# Configuración inicial: El texto empieza justo debajo de la pantalla
	var alto_pantalla = get_viewport().get_visible_rect().size.y
	label.position.y = alto_pantalla
	label.visible_ratio = 1.0 # En créditos el texto suele estar ya escrito
	
	# Iniciamos la música si tienes el nodo (opcional)
	if has_node("AudioStreamPlayer"): $MusicaCreditos.play()
	
	ejecutar_creditos()

func ejecutar_creditos() -> void:
	var alto_pantalla = get_viewport().get_visible_rect().size.y
	var altura_texto = label.get_content_height()
	
	# El destino es que el final del texto quede centrado o un poco arriba
	var destino_y = (alto_pantalla / 2) - (altura_texto / 2)
	
	# Si el texto es muy largo (muchos nombres), que suba hasta dejar ver el final
	if altura_texto > alto_pantalla:
		destino_y = margen_seguridad - (altura_texto - alto_pantalla / 2)
	
	# Calculamos la duración basada en la distancia para que la velocidad sea constante
	var distancia = abs(label.position.y - destino_y)
	var duracion = distancia / velocidad_subida
	
	if creditos_tween: creditos_tween.kill()
	creditos_tween = create_tween()
	creditos_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Animación de subida lineal (estilo cine)
	creditos_tween.tween_property(
		label, 
		"position:y", 
		destino_y, 
		duracion
	).set_trans(Tween.TRANS_LINEAR)
	
	# Al terminar, esperamos y volvemos al inicio
	creditos_tween.finished.connect(func():
		await get_tree().create_timer(pausa_final).timeout
		ir_al_inicio()
	)

func _process(_delta: float) -> void:
	# Acelerar créditos si dejan presionado Espacio/Select
	if creditos_tween and creditos_tween.is_running():
		if Input.is_action_pressed("ui_select"):
			creditos_tween.set_speed_scale(4.0)
		else:
			creditos_tween.set_speed_scale(1.0)

func _input(event: InputEvent) -> void:
	# Si presionan Enter/Aceptar, saltamos al inicio de una vez
	if event.is_action_pressed("ui_accept"):
		ir_al_inicio()

func ir_al_inicio() -> void:
	set_process_input(false) # Evitar doble llamada
	
	if creditos_tween:
		creditos_tween.kill()
		
	print("Regresando a la pantalla de título...")
	
	# Ocultamos el HUD por si acaso
	if is_instance_valid(PlayerHud):
		PlayerHud.hide()
		
	# Usamos el LevelManager para volver al menú principal de forma limpia
	# Cambia la ruta si tu escena de inicio se llama distinto
	LevelManager.load_new_level("res://title_scene/title_scene.tscn", "", Vector2.ZERO)
	
	queue_free()
