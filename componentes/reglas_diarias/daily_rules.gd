extends Control

@export var slide_length: int = 300  # Tiene que ser positivo
@export var animation_duration: float = 0.3  # Duración de la animación en segundos
#@onready var control_hover: Control = $shader TODO: Borrar si no hace nada

var initial_y: float
var tween: Tween = null

@onready var permitidos: Label = %AllowedLabel
@onready var restringidos: Label = %RestrictedLabel
@onready var prohibidos: Label = %ForbiddenLabel
@onready var dia: Label = %DayTitleLeftLabel
@onready var dia_2: Label = %DayTitleRightLabel
@onready var libro: NinePatchRect = $BookTexture
@onready var boton_movimiento: Button = %SlideButton


func _ready() -> void:
	# Inicializar posición
	initial_y = global_position.y
	# Inicializar shader
	if libro.material:
		libro.material.set_shader_parameter("outline_width", 0.0)


func _on_control_mouse_entered() -> void:
	if libro.material:
		libro.material.set_shader_parameter("outline_width", 0.002)
		#print("Hover activado")


func _on_control_mouse_exited() -> void:
	if libro.material:
		libro.material.set_shader_parameter("outline_width", 0.0)
		#print("Hover desactivado")


func _on_slide_button_pressed(toggled_on: bool) -> void:
	#print("Toggle: ", "activado" if toggled_on else "desactivado")
	_slide(toggled_on)


func _slide(toggled_on: bool) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	var target_pos = initial_y - slide_length if toggled_on else initial_y
	tween.tween_property(self, "position:y", target_pos, animation_duration)
