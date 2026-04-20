class_name Level extends Node2D

@export var music : AudioStream
@onready var enemy_counter : EnemyCounter = $EnemyCounter # Asegúrate de que el nombre coincida en el inspector
@onready var pressure_plate : PressurePlate = $PressurePlate # La placa que pusiste en la escena

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent( self )
	LevelManager.level_load_started.connect( _free_level )
	AudioManager.play_music( music )
	
	# --- NUEVA LÓGICA DEL LAB ---
	if enemy_counter:
		enemy_counter.enemies_defeated.connect( _on_lab_cleared )
	
	# Opcional: Asegurarnos de que la placa empiece oculta si no se ha matado a nadie
	if pressure_plate:
		pressure_plate.visible = false
		pressure_plate.process_mode = Node.PROCESS_MODE_DISABLED

func _on_lab_cleared() -> void:
	# 1. Actualizamos la Quest (Asegúrate que el título coincida con tu .tres)
	QuestManager.update_quest("Limpiar Laboratorio", "Científicos eliminados", true)
	
	# 2. Mostramos la placa
	if pressure_plate:
		pressure_plate.visible = true
		pressure_plate.process_mode = Node.PROCESS_MODE_INHERIT
		# Si tienes un ItemDropper, también lo puedes activar aquí:
		# $ItemDropper.drop_item()
		print("¡Laboratorio despejado! Placa activada.")

func _free_level() -> void:
	PlayerManager.unparent_player( self )
	queue_free()
