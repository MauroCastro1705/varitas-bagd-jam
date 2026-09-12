extends Node2D
@onready var items: Label = %items
@onready var aprobados: Label = %aprobados
@onready var detenidos: Label = %detenidos


func _ready() -> void:
	
	items.text = ", ".join(Global.items_confiscados)
	aprobados.text = ", ".join(Global.characters_aproved)
	detenidos.text = ", ".join(Global.characters_detained)
	
func _on_button_pressed() -> void:
	TransitionManager.change_scene("res://escenas/day_scene/nuevo_dia.tscn")
