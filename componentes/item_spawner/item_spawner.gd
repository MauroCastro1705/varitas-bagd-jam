class_name ItemSpawner extends Node2D

signal all_items_spawned()
signal item_spawned(item: Item)

@export_group("Spawn Area")
@export var spawn_area: Area2D

@export_group("Grid Configuration")
@export var columns: int = 3
@export var rows: int = 0
@export var horizontal_spacing: float = 120.0
@export var vertical_spacing: float = 120.0
@export var random_offset_range: float = 20.0

@export_group("Animation Settings")
@export var spawn_delay: float = 0.2
@export var fall_height: float = 200.0
@export var bounce_intensity: float = 30.0
@export var bounce_duration: float = 0.3
@export var wiggle_amount: float = 30.0
@export var fall_duration: float = 0.6

@export_group("Item Reference")
@export var item_scene: PackedScene

var spawn_queue: Array[ItemData] = []
var is_spawning: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var active_tweens: Array[Tween] = []


func _ready() -> void:
	if not spawn_area:
		push_error("ItemSpawner: No se asignó un área de spawn")
		return
	
	if not item_scene:
		push_error("ItemSpawner: No se asignó una escena de item")
		return
	
	if not spawn_area.is_inside_tree():
		await spawn_area.ready
	
	spawn_position = spawn_area.global_position


func spawn_items(items: Array[ItemData]) -> void:
	if is_spawning:
		push_warning("ItemSpawner: Ya está spawnando items, espera a que termine")
		return
	
	if items.is_empty():
		push_warning("ItemSpawner: Lista de items vacía")
		all_items_spawned.emit()
		return
	
	spawn_queue = items.duplicate()
	is_spawning = true
	
	if rows == 0:
		rows = ceil(float(spawn_queue.size()) / float(columns))
	
	_spawn_next_item()


func _spawn_next_item() -> void:
	if spawn_queue.is_empty():
		is_spawning = false
		all_items_spawned.emit()
		return
	
	var item_data = spawn_queue.pop_front()
	var item_instance = _create_item(item_data)
	
	var current_index = spawn_queue.size()
	var grid_position = _calculate_grid_position(current_index)
	
	var random_offset = Vector2(
		randf_range(-random_offset_range, random_offset_range),
		randf_range(-random_offset_range, random_offset_range)
	)
	
	var target_position = spawn_position + grid_position + random_offset
		
	_animate_item_fall(item_instance, target_position)
	item_spawned.emit(item_instance)
	
	if not spawn_queue.is_empty():
		await get_tree().create_timer(spawn_delay).timeout
		_spawn_next_item()
	else:
		await get_tree().create_timer(fall_duration + bounce_duration + 0.3).timeout
		is_spawning = false
		all_items_spawned.emit()


func _calculate_grid_position(index: int) -> Vector2:
	var column = index % columns
	var row = floor(float(index) / float(columns))
	
	var total_width = (columns - 1) * horizontal_spacing
	var total_height = (rows - 1) * vertical_spacing
	
	var offset_x = -total_width / 2.0
	var offset_y = -total_height / 2.0
	
	return Vector2(
		offset_x + column * horizontal_spacing,
		offset_y + row * vertical_spacing
	)


func _create_item(item_data: ItemData) -> Item:
	var instance = item_scene.instantiate()
	
	instance.data = item_data
	instance.global_position = spawn_position + Vector2(0, -fall_height)
	
	instance.is_being_dragged = false
	instance.process_mode = PROCESS_MODE_DISABLED
	
	spawn_area.add_child(instance)
	
	return instance


func _animate_item_fall(item: Item, target_position: Vector2) -> void:
	# Configuración de la animación
	var wiggle_direction = 1.0 if randf() > 0.5 else -1.0
	var wiggle_distance = randf_range(wiggle_amount * 0.5, wiggle_amount)
	var start_position = target_position + Vector2(0, -fall_height)
	
	# Posición inicial
	item.global_position = start_position
	item.scale = Vector2(0.8, 0.8)
	item.rotation = 0
	
	# Duración total de la animación
	var total_duration = fall_duration + bounce_duration + 0.2
	
	# Crear un solo tween con método personalizado
	var tween = create_tween()
	active_tweens.append(tween)
	
	# Usar tween_method para controlar toda la animación
	tween.tween_method(
		_update_animation.bind(item, start_position, target_position, wiggle_direction, wiggle_distance),
		0.0, 1.0, total_duration
	).set_ease(Tween.EASE_IN_OUT)
	
	# Esperar a que termine
	await tween.finished
	
	# Reactivar el item
	if is_instance_valid(item):
		item.process_mode = PROCESS_MODE_INHERIT
		item.z_index = 0
		item.global_position = target_position
		item.scale = Vector2(1.0, 1.0)
		item.rotation = 0
	
	# Limpiar tween
	active_tweens.erase(tween)


func _update_animation(progress: float, item: Item, start_pos: Vector2, target_pos: Vector2, wiggle_dir: float, wiggle_dist: float) -> void:
	if not is_instance_valid(item):
		return
	
	# Dividir la animación en fases
	var fall_end = fall_duration / (fall_duration + bounce_duration + 0.2)
	var bounce_end = (fall_duration + bounce_duration) / (fall_duration + bounce_duration + 0.2)
	
	var current_pos: Vector2
	var current_scale: Vector2
	var current_rotation: float
	
	if progress <= fall_end:
		# FASE 1: CAÍDA
		var fall_progress = progress / fall_end
		
		# Posición: caída con efecto lateral
		var base_pos = start_pos.lerp(target_pos, fall_progress)
		
		# Efecto lateral: máximo en el medio, cero al final
		var wiggle_factor = sin(fall_progress * PI) * (1 - fall_progress)
		var x_offset = wiggle_dir * wiggle_dist * wiggle_factor * 0.8
		
		current_pos = base_pos + Vector2(x_offset, 0)
		
		# Rotación durante la caída
		current_rotation = wiggle_dir * 0.03 * sin(fall_progress * PI * 3) * (1 - fall_progress)
		
		# Escala progresiva
		var scale_value = 0.8 + 0.2 * fall_progress
		current_scale = Vector2(scale_value, scale_value)
		
	elif progress <= bounce_end:
		# FASE 2: REBOTE
		var bounce_progress = (progress - fall_end) / (bounce_end - fall_end)
		
		# Efecto de rebote con amortiguación
		var bounce_factor = sin(bounce_progress * PI) * (1 - bounce_progress)
		var bounce_height = bounce_intensity * 0.5 * bounce_factor
		
		current_pos = target_pos + Vector2(0, -bounce_height)
		
		# Efecto de aplastamiento
		if bounce_progress < 0.3:
			# Aplastamiento al impactar
			var squash_progress = bounce_progress / 0.3
			current_scale = Vector2(1.0 + 0.1 * squash_progress, 1.0 - 0.1 * squash_progress)
		elif bounce_progress < 0.6:
			# Recuperación
			var recover_progress = (bounce_progress - 0.3) / 0.3
			current_scale = Vector2(1.1 - 0.1 * recover_progress, 0.9 + 0.1 * recover_progress)
		else:
			# Estabilización
			current_scale = Vector2(1.0, 1.0)
		
		# Rotación durante el rebote
		current_rotation = sin(bounce_progress * PI * 2) * 0.02
		
	else:
		# FASE 3: ESTABILIZACIÓN FINAL
		var final_progress = (progress - bounce_end) / (1.0 - bounce_end)
		
		current_pos = target_pos.lerp(target_pos, final_progress)
		current_scale = Vector2(1.0, 1.0)
		current_rotation = 0.0
	
	# Aplicar transformaciones
	item.global_position = current_pos
	item.scale = current_scale
	item.rotation = current_rotation


func stop_spawning() -> void:
	if is_spawning:
		is_spawning = false
		spawn_queue.clear()
		
		for tween in active_tweens:
			if is_instance_valid(tween):
				tween.kill()
		active_tweens.clear()
		
		all_items_spawned.emit()


func clear_items() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
	
	for child in spawn_area.get_children():
		if child is Item:
			child.queue_free()


func get_items_in_area() -> Array[Item]:
	var items: Array[Item] = []
	for child in spawn_area.get_children():
		if child is Item:
			items.append(child)
	return items


func _exit_tree() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
