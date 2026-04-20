class_name PressurePlate extends Node2D

# No tocamos tus señales originales
signal activated
signal deactivated

var bodies : int = 0
var is_active : bool = false
var off_rect : Rect2

@onready var area_2d : Area2D = $Area2D
@onready var sprite : Sprite2D = $Sprite2D
@onready var audio : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_activate : AudioStream = preload("res://Interactables/dungeon/lever-01.wav")

func _ready() -> void:
	area_2d.body_entered.connect( _on_body_entered )
	area_2d.body_exited.connect( _on_body_exited )
	off_rect = sprite.region_rect
	
	# EMPIEZA MUERTA: Invisible y sin colisión
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

# Esta es la función que llamaremos cuando mueran los científicos
func aparecer() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	# Aquí podrías poner un efecto de sonido de "aparición mágica"
	print("Placa revelada.")

func _on_body_entered( b : Node2D ) -> void:
	bodies += 1
	if bodies > 0:
		# PISAR = VIAJE INSTANTÁNEO
		PlayerManager.viaje_unico_a_michael()
		activated.emit()

func _on_body_exited( b : Node2D ) -> void:
	bodies -= 1
	deactivated.emit()

func play_audio( _stream : AudioStream ) -> void:
	audio.stream = _stream
	audio.play()
