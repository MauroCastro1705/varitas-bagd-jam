extends Control

@export var fade_duration: float = 0.5
@onready var start_button: Button = $StartButton


func _on_start_button_pressed() -> void:
	TransitionManager.change_scene("res://escenas/day_scene/nuevo_dia.tscn")


func _on_creditos_pressed() -> void:
	TransitionManager.change_scene("res://escenas/creditos/creditos.tscn")
