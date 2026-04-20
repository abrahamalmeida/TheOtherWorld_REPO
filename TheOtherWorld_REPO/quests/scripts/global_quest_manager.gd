## QUEST MANAGER - GLOBAL SCRIPT
extends Node

signal quest_updated( q )

const QUEST_DATA_LOCATION : String = "res://quests/"

var quests : Array[ Quest ]
var current_quests : Array = []

func _ready() -> void:
	# gather all quests
	gather_quest_data()

func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_pressed("test"):
		print( "quests: ", current_quests )

func gather_quest_data() -> void:
	# Gather all quest resources and add to quests array
	if not DirAccess.dir_exists_absolute(QUEST_DATA_LOCATION):
		printerr("ERROR: La carpeta de quests no existe en: ", QUEST_DATA_LOCATION)
		return
		
	var quest_files : PackedStringArray = DirAccess.get_files_at( QUEST_DATA_LOCATION )
	quests.clear()
	for q in quest_files:
		if q.ends_with(".tres"): # Solo cargamos recursos de Godot
			var resource = load( QUEST_DATA_LOCATION + "/" + q )
			if resource is Quest:
				quests.append( resource )
	pass

# Update the status of a quest
func update_quest( _title : String, _completed_step : String = "", _is_complete : bool = false ) -> void:
	var quest_index : int = get_quest_index_by_title( _title )
	
	if quest_index == -1:
		# Quest was not found - add it to the current quests array
		var new_quest : Dictionary = {
				title = _title,
				is_complete = _is_complete,
				completed_steps = []
		}
		
		if _completed_step != "":
			new_quest.completed_steps.append( _completed_step.to_lower() )
		
		current_quests.append( new_quest )
		quest_updated.emit( new_quest )
		
		# Display a notification that quests was added
		PlayerHud.queue_notification( "Quest Started", _title )
	else:
		# Quest was found, update it
		var q = current_quests[ quest_index ]
		if _completed_step != "" and q.completed_steps.has( _completed_step ) == false:
			q.completed_steps.append( _completed_step.to_lower() )
		
		q.is_complete = _is_complete
		quest_updated.emit( q )
		
		# Display a notification that quests was updated OR completed
		if q.is_complete == true:
			PlayerHud.queue_notification( "Quest Complete!", _title )
			
			# FIX CRÍTICO: Verificamos que el recurso .tres exista antes de dar premios
			var quest_resource = find_quest_by_title( _title )
			if quest_resource != null:
				disperse_quest_rewards( quest_resource )
			else:
				printerr("ERROR: No se encontró el recurso .tres para '", _title, "'. Revisa que el Title en el inspector sea idéntico.")
		else:
			PlayerHud.queue_notification( "Quest Updated", _title + ": " + _completed_step )

func disperse_quest_rewards( _q : Quest ) -> void:
	# Si por algún milagro _q llega nulo aquí, salimos de una
	if _q == null: return

	# Construimos el mensaje de recompensa
	var _message : String = str( _q.reward_xp ) + "xp"
	
	# RECOMPENSA DE XP (Solo si el PlayerManager está listo)
	if PlayerManager.has_method("reward_xp"):
		PlayerManager.reward_xp( _q.reward_xp )
	
	# RECOMPENSA DE ITEMS
	for i in _q.reward_items:
		if i.item != null:
			PlayerManager.INVENTORY_DATA.add_item( i.item, i.quantity )
			_message += ", " + i.item.name + " x" + str( i.quantity )
	
	PlayerHud.queue_notification( "Quest Rewards Received!", _message )

# Provide a quest and return the current quest associated with it
func find_quest( _quest : Quest ) -> Dictionary:
	for q in current_quests:
		if q.title.to_lower() == _quest.title.to_lower():
			return q
	return { title = "not found", is_complete = false, completed_steps = [''] }

# Take title and find associated Quest resource
func find_quest_by_title( _title : String ) -> Quest:
	for q in quests:
		# Comparamos quitando espacios vacíos para evitar errores tontos
		if q.title.strip_edges().to_lower() == _title.strip_edges().to_lower():
			return q
	return null

# Find quest by title name, and return index in Current Quests array
func get_quest_index_by_title( _title : String ) -> int:
	for i in current_quests.size():
		if current_quests[ i ].title.to_lower() == _title.to_lower():
			return i
	return -1

func sort_quests() -> void:
	var active_quests : Array = []
	var completed_quests : Array = []
	for q in current_quests:
		if q.is_complete:
			completed_quests.append( q )
		else:
			active_quests.append( q )
	
	active_quests.sort_custom( sort_quests_ascending )
	completed_quests.sort_custom( sort_quests_ascending )
	
	current_quests = active_quests
	current_quests.append_array( completed_quests )

func sort_quests_ascending( a, b ):
	if a.title < b.title:
		return true
	return false
