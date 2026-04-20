extends Button

# Arrastra aquí tu escena de la historia desde el sistema de archivos
@export var historia_scene_path : String = "res://historia_inicial.tscn"

func _on_nuevo_juego_pressed() -> void:

	
	# 2. Cambiamos a la escena de la historia
	var error = get_tree().change_scene_to_file("res://Levels/Area01/02.tscn")
	
	if error != OK:
		print("Error al cargar la escena de la historia: ", error)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_nuevo_juego_pressed()
