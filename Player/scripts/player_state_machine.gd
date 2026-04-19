class_name PlayerStateMachine extends Node

var states : Array[ State ]
var prev_state : State
var current_state : State
var next_state : State

func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta):
	# SEGURIDAD: Solo procesamos si el estado es válido
	if is_instance_valid(current_state):
		change_state( current_state.process( delta ) )

func _physics_process(delta):
	# SEGURIDAD: Solo procesamos física si el estado es válido
	if is_instance_valid(current_state):
		change_state( current_state.physics( delta ) )

func _unhandled_input(event):
	# EL ESCUDO: Aquí es donde te daba el error de la línea 21. 
	# Ahora verifica si el estado existe antes de llamarlo.
	if current_state == null or not is_instance_valid(current_state):
		return
		
	var next = current_state.handle_input( event )
	if next:
		change_state( next )

func Initialize( _player : Player ) -> void:
	states = []
	
	for c in get_children():
		if c is State:
			states.append(c)
	
	if states.size() == 0:
		return
	
	# Pasamos la referencia del player a todos los estados de forma segura
	for state in states:
		state.player = _player
		state.state_machine = self
		state.init()
	
	change_state( states[0] )
	process_mode = Node.PROCESS_MODE_INHERIT

func change_state( new_state : State ) -> void:
	# Verificamos que el nuevo estado sea válido y no sea el mismo
	if new_state == null or new_state == current_state or not is_instance_valid(new_state):
		return
	
	
	next_state = new_state
	
	if current_state and is_instance_valid(current_state):
		current_state.exit()
	
	prev_state = current_state
	current_state = new_state
	current_state.enter()
