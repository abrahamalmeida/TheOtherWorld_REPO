class_name State_Cutscene extends State

@onready var idle: State = $"../Idle"

func init() -> void:
	# Conectamos las señales del sistema de diálogo
	DialogSystem.started.connect( _on_dialog_started )
	DialogSystem.finished.connect( _on_dialog_finished )

func enter() -> void:
	if player:
		player.update_animation("idle")
		# Mantenemos al jugador procesando aunque el resto del mundo se pause
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.velocity = Vector2.ZERO

func exit() -> void:
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT

func process( _delta : float ) -> State:
	player.velocity = Vector2.ZERO
	return null

func _on_dialog_started() -> void:
	# Solo cambiamos a este estado si este personaje es el activo actualmente
	if PlayerManager.player == player:
		state_machine.change_state( self )

func _on_dialog_finished() -> void:
	if state_machine.current_state == self:
		state_machine.change_state( idle )
