extends Node2D

@onready var timer: Timer = $Timer


func _on_timer_timeout() -> void:
	TransitionManager.change_scene("res://escenas/main_menu/MainMenu.tscn")
