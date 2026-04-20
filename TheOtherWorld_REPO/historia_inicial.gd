extends CanvasLayer

@onready var label = $ColorRect/RichTextLabel
@onready var color_rect = $ColorRect # Necesitaremos mover el contenedor o el label

var velocidad_base = 0.04
var velocidad_rapida = 0.005 
var pausa_entre_parrafos = 1.5
var distancia_movimiento = 200 # Cuántos píxeles subirá el texto

var intro_tween : Tween 

func _ready():
	get_tree().paused = false 
	
	if label == null:
		return
		
	label.visible_ratio = 0
	# Opcional: Empezar un poco más abajo para que se note el movimiento
	# label.position.y += 50 
	
	ejecutar_introduccion()

func ejecutar_introduccion():
	var texto_completo = label.text
	var total_caracteres = texto_completo.length()
	
	var punto_partida = texto_completo.find("\n") + 1
	var ratio_fecha = float(punto_partida) / total_caracteres
	
	intro_tween = create_tween()
	intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	# --- ANIMACIÓN DE APARICIÓN (Ajustada) ---
	# Primera parte (Fecha)
	intro_tween.tween_property(label, "visible_ratio", ratio_fecha, punto_partida * velocidad_base)
	intro_tween.tween_interval(pausa_entre_parrafos)
	
	# Segunda parte + MOVIMIENTO HACIA ARRIBA
	# Usamos parallel() para que el texto se escriba y suba AL MISMO TIEMPO
	var duracion_final = (total_caracteres - punto_partida) * velocidad_base
	
	intro_tween.tween_property(label, "visible_ratio", 1.0, duracion_final)
	
	# Esta línea hace que el texto suba mientras se escribe
	intro_tween.parallel().tween_property(label, "position:y", label.position.y - distancia_movimiento, duracion_final)
	
	# Al terminar todo, esperamos un poco y cambiamos de nivel solo
	intro_tween.finished.connect(func(): 
		await get_tree().create_timer(2.0).timeout
		saltar_a_nivel()
	)

func _process(_delta):
	if intro_tween and intro_tween.is_running():
		if Input.is_action_pressed("ui_select"): 
			intro_tween.set_speed_scale(8.0) 
		else:
			intro_tween.set_speed_scale(1.0) 

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if label.visible_ratio < 1.0:
			if intro_tween:
				intro_tween.kill()
			label.visible_ratio = 1.0
			# Si saltamos la animación, también deberíamos poner la posición final
			# label.position.y -= distancia_movimiento 
			print("Animación saltada.")
		else:
			saltar_a_nivel()

func saltar_a_nivel():
	print("Cambiando al nivel 02...")
	if PlayerHud:
		PlayerHud.show()
		PlayerHud.update_hp(PlayerManager.player.hp, PlayerManager.player.max_hp)

	PlayerManager.force_player_reset()
	LevelManager.load_new_level("res://Levels/Area01/02_shop.tscn", "", Vector2.ZERO)
	queue_free()
