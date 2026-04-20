class_name PersistentDataHandler extends Node

signal data_loaded
var value : bool = false

func _ready() -> void:
	# Damos tiempo a Godot para montar la escena
	await get_tree().process_frame
	get_value()

func set_value() -> void:
	var id = _get_name()
	if id != "":
		SaveManager.add_persistent_value(id)
		value = true

func get_value() -> void:
	var id = _get_name()
	if id != "":
		value = SaveManager.check_persistent_value(id)
		data_loaded.emit()

func _get_name() -> String:
	# Triple protección para evitar el crash de 'null instance'
	if not is_inside_tree() or get_tree() == null or get_tree().current_scene == null:
		return ""
	return get_tree().current_scene.scene_file_path + "/" + get_parent().name + "/" + name
