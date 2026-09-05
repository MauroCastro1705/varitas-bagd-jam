class_name Item extends Node2D

signal tooltip_requested(data: ItemData, item_global_pos: Vector2)
signal tooltip_hidden()

@export var data: ItemData

var is_being_dragged: bool = false

# Estado temporal mientras el item está sobre un socket
var is_hovering_socket: bool = false
var drop_socket_ref: StaticBody2D = null

# Estado permanente cuando el item está en un socket
var occupied_socket: StaticBody2D = null

var offset: Vector2 = Vector2(0.0, 0.0)
var particles: CPUParticles2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


func _ready() -> void:
	if not data:
		return
	#data.item_name
	#data.item_description
	#data.sfx
	#data.vfx
	if data.sprite:
		sprite.texture = data.sprite
		# Crea un rectángulo que cubre por completo la textura
		var rect = RectangleShape2D.new()
		rect.size = data.sprite.get_size()
		# Y aplica ese rectángulo como forma de colisión
		collision_shape.shape = rect

	if data.vfx:
		particles = data.vfx.instantiate()
		self.add_child(particles)
		particles.emitting = false # Iniciar apagadas por defecto


func _input(event: InputEvent) -> void:
	if not is_being_dragged: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		Global.is_dragging = false
		self.is_being_dragged = false

		if particles:
			particles.emitting = false

		if is_hovering_socket:
			var tween = get_tree().create_tween()
			tween.tween_property(self, "global_position", drop_socket_ref.global_position, 0.05).set_ease(Tween.EASE_OUT)

			# Agregar referencia a instancia de este Item a lista de confiscados
			if not self in Global.items_confiscados:
				Global.items_confiscados.append(self)
				Global.objeto_confiscado.emit()
				print("Items confiscados: ", Global.items_confiscados)

			occupied_socket = drop_socket_ref
			occupied_socket.get_node("CollisionShape2D").set_deferred("disabled", true)
		else:
			tooltip_requested.emit(data, self.global_position)

		# Resettear índice z al soltar y dejar por encima de todo otro item
		self.z_index = 10
		if get_parent():
			get_parent().move_child(self, -1)


func _physics_process(_delta: float) -> void:
	if self.is_being_dragged:
		var target_pos: Vector2 = get_global_mouse_position() - self.offset
		
		if Global.drag_limits:
			var limits = Global.drag_limits
			target_pos.x = clamp(target_pos.x, limits.position.x, limits.end.x)
			target_pos.y = clamp(target_pos.y, limits.position.y, limits.end.y)

		self.global_position = target_pos


func _handle_left_mouse_down() -> void:
	# Como todo lo que sigue es lógica de arrastrar, si ya lo estoy haciendo no debería seguir
	if Global.is_dragging:
		return

	var local_click_pos = sprite.get_local_mouse_position()

	# Chequeo si estoy clickeando sobre la parte no transparente de la textura
	if sprite.is_pixel_opaque(local_click_pos):
		if self in Global.items_confiscados:
			Global.items_confiscados.erase(self)

		if occupied_socket:
			occupied_socket.get_node("CollisionShape2D").set_deferred("disabled", false)
			occupied_socket = null

		Global.is_dragging = true
		self.is_being_dragged = true
		self.offset = get_global_mouse_position() - self.global_position

		tooltip_hidden.emit()
		if particles:
			particles.emitting = true

		# Mandar al frente
		self.z_index = 100

		# Consumir click para no propagar a otros items
		get_viewport().set_input_as_handled()


func _on_area_2d_mouse_entered():
	if not Global.is_dragging:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
		
		tooltip_requested.emit(data, self.global_position)


func _on_area_2d_mouse_exited():
	if not Global.is_dragging:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)	
		tooltip_hidden.emit()


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Manejar mouse button down
		if event.pressed:
			_handle_left_mouse_down()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('sockets'):
		is_hovering_socket = true
		body.modulate = Color(Color.GHOST_WHITE, 1.0)
		drop_socket_ref = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('sockets'):
		is_hovering_socket = false
		body.modulate = Color(Color.GHOST_WHITE, 0.7)
		drop_socket_ref = null
