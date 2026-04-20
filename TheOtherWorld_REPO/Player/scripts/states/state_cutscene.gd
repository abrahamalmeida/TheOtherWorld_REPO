class_name State_Cutscene extends State

@onready var idle: State = $"../Idle"

func init() -> void:
	# Conectamos de forma segura para evitar duplicados
	if not DialogSystem.started.is_connected(_on_dialog_started):
		DialogSystem.started.connect( _on_dialog_started )
	if not DialogSystem.finished.is_connected(_on_dialog_finished):
		DialogSystem.finished.connect( _on_dialog_finished )

func _exit_tree() -> void:
	# IMPORTANTE: Desconectar al salir para evitar errores de memoria/escena
	if DialogSystem.started.is_connected(_on_dialog_started):
		DialogSystem.started.disconnect( _on_dialog_started )
	if DialogSystem.finished.is_connected(_on_dialog_finished):
		DialogSystem.finished.disconnect( _on_dialog_finished )

func enter() -> void:
	if player:
		player.update_animation("idle")
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.velocity = Vector2.ZERO

func exit() -> void:
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT

func process( _delta : float ) -> State:
	player.velocity = Vector2.ZERO
	return null

func _on_dialog_started() -> void:
	# Solo activamos la cinemática si este personaje es el actual
	if PlayerManager.player == player:
		state_machine.change_state( self )

func _on_dialog_finished() -> void:
	if state_machine.current_state == self:
		state_machine.change_state( idle )
