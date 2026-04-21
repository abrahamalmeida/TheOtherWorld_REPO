extends CanvasLayer

@onready var label: RichTextLabel = $ColorRect/RichTextLabel
@onready var color_rect = $ColorRect

# --- AJUSTES CINEMÁTICOS ---
@export var velocidad_escritura : float = 0.08  # Más alto = más lento
@export var pausa_inicial : float = 2.0
@export var margen_final_pixeles : float = 100.0 # Espacio que queda abajo al terminar

var intro_tween : Tween 

func _ready() -> void:
	# Aseguramos que el juego no esté pausado
	get_tree().paused = false 
	
	if not is_instance_valid(label):
		print("Error: No se encontró el RichTextLabel")
		return
		
	# Preparación inicial del texto
	label.visible_ratio = 0
	# Empezamos el texto en la mitad inferior para que tenga espacio de subir
	label.position.y = get_viewport().get_visible_rect().size.y * 0.7
	
	ejecutar_introduccion()

func ejecutar_introduccion() -> void:
	var texto_completo = label.text
	var total_caracteres = texto_completo.length()
	
	# Buscamos la primera pausa (el primer salto de línea)
	var punto_partida = texto_completo.find("\n") + 1
	if punto_partida <= 0: punto_partida = 10
	var ratio_fecha = float(punto_partida) / total_caracteres
	
	if intro_tween: intro_tween.kill()
	intro_tween = create_tween()
	intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	# --- PASO 1: ESCRIBIR LA FECHA ---
	intro_tween.tween_property(label, "visible_ratio", ratio_fecha, punto_partida * velocidad_escritura)
	intro_tween.tween_interval(pausa_inicial)
	
	# --- PASO 2: ESCRIBIR EL CUERPO Y SUBIR SIN PASARSE ---
	var caracteres_restantes = total_caracteres - punto_partida
	var duracion_final = caracteres_restantes * velocidad_escritura
	
	# CÁLCULO DEL LÍMITE (Evita el bloque vacío)
	# Queremos que la última línea del texto se detenga antes de salir de la pantalla
	var alto_pantalla = get_viewport().get_visible_rect().size.y
	var altura_real_texto = label.get_content_height()
	
	# El destino es: que el final del texto quede a "margen_final_pixeles" del borde inferior
	var destino_y = alto_pantalla - altura_real_texto - margen_final_pixeles
	
	# Si el texto es corto y el destino es más abajo de donde ya estamos, forzamos un movimiento leve
	if destino_y > label.position.y:
		destino_y = label.position.y - 150

	# Ejecución en paralelo
	intro_tween.tween_property(label, "visible_ratio", 1.0, duracion_final)
	intro_tween.parallel().tween_property(
		label, 
		"position:y", 
		destino_y, 
		duracion_final
	).set_trans(Tween.TRANS_LINEAR)
	
	# Al terminar, esperamos y cargamos el nivel
	intro_tween.finished.connect(func(): 
		await get_tree().create_timer(3.0).timeout
		saltar_a_nivel()
	)

func _process(_delta: float) -> void:
	# Sistema de aceleración manual (Select/Espacio)
	if intro_tween and intro_tween.is_running():
		if Input.is_action_pressed("ui_select"): 
			intro_tween.set_speed_scale(3.0) 
		else:
			intro_tween.set_speed_scale(1.0) 

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if label.visible_ratio < 0.95:
			# Saltar animación
			if intro_tween: intro_tween.kill()
			label.visible_ratio = 1.0
			# Ajuste manual rápido de posición para que se vea el final
			label.position.y -= 100 
			print("Intro saltada.")
		else:
			saltar_a_nivel()

func saltar_a_nivel() -> void:
	# Bloqueamos el input para evitar doble ejecución
	set_process_input(false)
	
	print("Cambiando al nivel de la tienda...")
	
	# Mostramos el HUD
	if is_instance_valid(PlayerHud):
		PlayerHud.show()
		# Actualización segura de HP
		if PlayerManager.player:
			PlayerHud.update_hp(PlayerManager.player.hp, PlayerManager.player.max_hp)

	# Reset de estado del jugador (evita que se mueva en la carga)
	PlayerManager.force_player_reset()
	
	# Cambio de nivel diferido para que la Victus no sufra
	LevelManager.load_new_level("res://creditos.tscn", "", Vector2.ZERO)
	
	# Eliminamos la intro de la memoria
	queue_free()
