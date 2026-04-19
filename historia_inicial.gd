extends CanvasLayer

@onready var label = $ColorRect/RichTextLabel
var velocidad_base = 0.04
var velocidad_rapida = 0.005 # Velocidad cuando presionas Espacio
var pausa_entre_parrafos = 1.5

var intro_tween : Tween # Guardamos el tween aquí para poder manipularlo

func _ready():
	get_tree().paused = false 
	
	if label == null:
		return
		
	label.visible_ratio = 0
	ejecutar_introduccion()

func ejecutar_introduccion():
	var texto_completo = label.text
	var total_caracteres = texto_completo.length()
	
	var punto_partida = texto_completo.find("\n") + 1
	var ratio_fecha = float(punto_partida) / total_caracteres
	
	# Creamos el tween y lo asignamos a nuestra variable
	intro_tween = create_tween()
	intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	# Primera parte (Fecha)
	intro_tween.tween_property(label, "visible_ratio", ratio_fecha, punto_partida * velocidad_base)
	intro_tween.tween_interval(pausa_entre_parrafos)
	# Segunda parte (Resto del texto)
	intro_tween.tween_property(label, "visible_ratio", 1.0, (total_caracteres - punto_partida) * velocidad_base)

func _process(_delta):
	# Lógica para acelerar con ESPACIO
	if intro_tween and intro_tween.is_running():
		if Input.is_action_pressed("ui_select"): # "ui_select" suele ser Espacio
			intro_tween.set_speed_scale(8.0) # Lo hace 8 veces más rápido
		else:
			intro_tween.set_speed_scale(1.0) # Velocidad normal

func _input(event):
	# Lógica para saltar con ENTER
	if event.is_action_pressed("ui_accept"):
		if label.visible_ratio < 1.0:
			# Si hay un tween corriendo, lo matamos para que no siga moviendo el ratio
			if intro_tween:
				intro_tween.kill()
			
			label.visible_ratio = 1.0
			print("Animación saltada.")
		else:
			saltar_a_nivel()

func saltar_a_nivel():
	print("Cambiando al nivel 02...")
	
	# 1. Forzamos que el HUD se muestre antes de irnos
	if PlayerHud:
		PlayerHud.show()
		# Si tienes el código que te pasé antes, esto despertará los corazones
		PlayerHud.update_hp(PlayerManager.player.hp, PlayerManager.player.max_hp)

	# 2. Limpiamos al jugador
	PlayerManager.force_player_reset()
	
	# 3. CAMBIO IMPORTANTE: Cargamos el nivel y LUEGO borramos la intro
	LevelManager.load_new_level("res://Levels/Area01/02.tscn", "", Vector2.ZERO)
	
	# Borramos esta escena de la memoria para que su ColorRect no tape nada
	queue_free()
