extends Control
## Libro confiscar

@export_range(0, 1080, 10, "prefer_slider") var slide_length: int = 300
@export var animation_duration: float = 0.3  # Duración de la animación en segundos

# Reglas del libro
@export var reglas1:String = "-Confiscar cualquier poción de veneno
-Confiscar cualquier poción de acido" 
@export var reglas2:String = "-Confiscar cualquier gorro puntiagudo de color negro. 
-Confiscar cualquier pergamino que contenga hechizos para revivir a los muertos"

var initial_y: float
var tween: Tween = null

var button_small_size:Vector2 = Vector2(362.0, 434.0)
var button_big_size:Vector2 = Vector2(711.0, 434.0)

@onready var boton_movimiento: Button = %SlideButton
@onready var libro_abierto: NinePatchRect = $Libro_abierto
@onready var libro_cerrado: NinePatchRect = $Libro_cerrado

@onready var pagina_1: Label = %pagina1
@onready var pagina_2: Label = %pagina2


func _ready() -> void:
	libro_abierto.hide()
	libro_cerrado.show()
	achicar_boton()
	# Inicializar posición
	initial_y = global_position.y
	# Inicializar shader
	if libro_abierto.material:
		libro_abierto.material.set_shader_parameter("outline_width", 0.0)
	pagina_1.text = reglas1
	pagina_2.text = reglas2


func _on_control_mouse_entered() -> void:
	if get_parent() and boton_movimiento.button_pressed:
		get_parent().move_child(self, -1)
	if libro_abierto.material:
		libro_abierto.material.set_shader_parameter("outline_width", 0.002)


func _on_control_mouse_exited() -> void:
	if libro_abierto.material:
		libro_abierto.material.set_shader_parameter("outline_width", 0.0)


func _on_slide_button_pressed(toggled_on: bool) -> void:
	if get_parent():
		get_parent().move_child(self, -1)
	_slide(toggled_on)
	if toggled_on:
		libro_abierto.show()
		libro_cerrado.hide()
		agrandar_boton()
	else:
		libro_abierto.hide()
		libro_cerrado.show()
		achicar_boton()


func _slide(toggled_on: bool) -> void:
	if tween and tween.is_running():
		tween.kill()

	var target_pos = initial_y - slide_length if toggled_on else initial_y

	tween = create_tween()\
	.set_ease(Tween.EASE_IN_OUT)\
	.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(self, "position:y", target_pos, animation_duration)

func achicar_boton():
	boton_movimiento.size = button_small_size

func agrandar_boton():
	boton_movimiento.size = button_big_size
