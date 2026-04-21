extends CanvasLayer

signal shown
signal hidden

@onready var control: Control = $Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	shown.emit()

func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	hidden.emit()

# Funciones vacías para evitar errores de otros scripts
func update_ability_items(_i): pass
func focused_item_changed(_s): pass
func update_item_description(_t): pass
func preview_stats(_item): pass
