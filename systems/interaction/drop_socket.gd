extends StaticBody2D


@onready var highlight: CPUParticles2D = $DropHighlight


func _process(_delta: float) -> void:
	highlight.emitting = true if Global.is_dragging else false #TODO: Cambiar por algo menos croto
