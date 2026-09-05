extends Control

@export var _persistent_foreground_scene : PackedScene = preload("res://escenas/transition_scene/persistent_foreground_scene.tscn")

var fondo: ColorRect

var _foreground_canvas : CanvasLayer
var _foreground_scene : Control
var _transition_effect : ColorRect
var _transition_tween : Tween
var _is_transitioning: bool = false
@warning_ignore("unused_private_class_variable")
var _transition_callback: Callable  # Para ejecutar después de la transición

signal scene_changed  # Señal para cuando la transición termina
signal transition_started  # Señal para cuando la transición comienza
signal transition_finished  # Señal para cuando la transición termina

func _ready():
	get_tree().scene_changed.connect(_scene_changed_callback)
	
	_foreground_canvas = CanvasLayer.new()
	_foreground_canvas.layer = 1000
	add_child(_foreground_canvas)
	
	_foreground_scene = _persistent_foreground_scene.instantiate()
	_foreground_canvas.add_child(_foreground_scene)
	
	# Buscar el efecto de varias formas
	_transition_effect = _foreground_scene.get_node("TransitionEffect") as ColorRect
	
	if not _transition_effect:
		_transition_effect = _foreground_scene.get_node_or_null("%TransitionEffect")
	
	if _transition_effect:
		_transition_effect.visible = false
		print("✅ Transición encontrada: ", _transition_effect.name)
	else:
		push_error("❌ No se encontró TransitionEffect. Revisa la escena.")
		for child in _foreground_scene.get_children():
			if child is ColorRect:
				_transition_effect = child
				print("⚠️ Usando ColorRect encontrado: ", child.name)
				break
	
	fondo = _foreground_scene.get_node_or_null("fondo")
	if fondo:
		fondo.visible = false

var _transition_effect_parameter_call = func(value : float):
	if not _transition_effect:
		return
	_transition_effect.material.set_shader_parameter("progress", value)
	_transition_effect.material.set_shader_parameter("background_threshold", abs(1.0 - value*2.0) - 0.5)
	_transition_effect.material.set_shader_parameter("color_threshold", min(1.0, abs(-4.0 + value*8.0)) * 0.48)

func change_scene(scene_path : String):
	if _is_transitioning:
		push_warning("Ya hay una transición en curso")
		return
	
	_is_transitioning = true
	transition_started.emit()
	
	if not _transition_effect:
		if scene_path != "":
			get_tree().change_scene_to_file(scene_path)
		_is_transitioning = false
		transition_finished.emit()
		return
	
	if _transition_tween:
		_transition_tween.kill()
		_transition_tween = null
	
	# Mostrar fondo negro
	if fondo:
		fondo.visible = true
	
	_transition_effect.material.set_shader_parameter("seed", randf())
	_transition_effect.visible = true
	
	_transition_tween = create_tween()
	_transition_tween.tween_method(_transition_effect_parameter_call, 0.0, 0.5, 0.5)
	
	if scene_path != "":
		# Si hay una escena, cambiar después de la transición
		_transition_tween.tween_callback(_change_scene_delayed.bind(scene_path))
	else:
		# Si no hay escena, solo hacer la transición visual y llamar al callback
		_transition_tween.tween_callback(_on_visual_transition_complete)

func _change_scene_delayed(scene_path : String):
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	_scene_changed_callback()

func _on_visual_transition_complete():
	"""Callback cuando solo es una transición visual (para cambio de habitaciones)"""
	_is_transitioning = false
	transition_finished.emit()
	scene_changed.emit()

func _scene_changed_callback():
	"""Callback cuando la escena cambia (para transiciones de escena completa)"""
	if not _transition_effect:
		_is_transitioning = false
		transition_finished.emit()
		return
	
	if _transition_tween:
		_transition_tween.kill()
		_transition_tween = null
	
	# Iniciar la transición de salida
	_transition_tween = create_tween()
	_transition_tween.tween_method(_transition_effect_parameter_call, 0.5, 1.0, 0.5)
	_transition_tween.tween_callback(_hide_transition)

func _hide_transition():
	if _transition_effect:
		_transition_effect.visible = false
	if fondo:
		fondo.visible = false
	_is_transitioning = false
	transition_finished.emit()
	scene_changed.emit()

# Función auxiliar para esperar a que termine la transición
func wait_for_transition():
	"""Espera a que la transición actual termine"""
	while _is_transitioning:
		await get_tree().process_frame
