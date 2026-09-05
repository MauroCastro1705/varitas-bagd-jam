extends Control
class_name DialogScene

## Señales
signal dialog_started
signal dialog_finished
signal dialog_updated(line_index: int)

## Configuración
@export var typing_speed: float = 0.01  ## Segundos entre cada letra, mientras mas chico mas rapido
@export var character_dialog: Array = []  ## donde se guarda el dialogo

## Nodos UI
@onready var name_label: Label = %npc_name
@onready var text_label: RichTextLabel = %dialogo
@onready var next_button: Button = %next
@onready var panel: NinePatchRect = $panel

## Variables internas
var dialog_lines: Array[DialogLine] = []
var current_line_index: int = 0
var is_typing: bool = false
var is_dialog_active: bool = false
var typing_timer: float = 0.0
var current_char_index: int = 0
var current_text: String = ""

## Clase para líneas de diálogo
class DialogLine:
	var character_name: String
	var text: String
	
	func _init(p_character_name: String = "", p_text: String = ""):
		character_name = p_character_name
		text = p_text

func _ready():
	visible = false
	hide()
	
	# Si hay diálogo genérico configurado, iniciarlo automáticamente
	if not character_dialog.is_empty():
		start_dialog_from_dictionary(character_dialog)

# dialogo desde un array
func start_dialog(lines: Array[DialogLine]) -> void:
	if lines.is_empty():
		return
	
	dialog_lines = lines
	current_line_index = 0
	is_dialog_active = true
	
	visible = true
	show()
	
	_show_line(current_line_index)
	dialog_started.emit()

# dialogo desde un array de diccionarios (formato simplificado)
func start_dialog_from_dictionary(dialog_data: Array) -> void:
	if dialog_data.is_empty():
		return
	
	var lines: Array[DialogLine] = []
	var character_name: String = ""
	
	# Verificar si el primer elemento es un string (nombre)
	if dialog_data.size() > 0 and typeof(dialog_data[0]) == TYPE_STRING:
		character_name = dialog_data[0]
		# Comenzar desde el índice 1 para las líneas
		var start_index = 1
		for i in range(start_index, dialog_data.size()):
			var line_data = dialog_data[i]
			var text_content = ""
			
			# Si el elemento es un string, usarlo directamente
			if typeof(line_data) == TYPE_STRING:
				text_content = line_data
			# Si es un diccionario, buscar el texto
			elif typeof(line_data) == TYPE_DICTIONARY:
				text_content = line_data.get("text", "")
				if text_content.is_empty():
					text_content = line_data.get("dialog", "")
			
			if not text_content.is_empty():
				lines.append(DialogLine.new(character_name, text_content))
	else:
		# Formato antiguo (compatibilidad)
		for line_data in dialog_data:
			var char_name = line_data.get("character_name", "")
			if char_name.is_empty():
				char_name = line_data.get("name", "")
			
			var text_content = line_data.get("text", "")
			if text_content.is_empty():
				text_content = line_data.get("dialog", "")
			
			if not text_content.is_empty():
				lines.append(DialogLine.new(char_name, text_content))
	
	start_dialog(lines)

# Inicia dialogo
func start_generic_dialog() -> void:
	if character_dialog.is_empty():
		return
	
	start_dialog_from_dictionary(character_dialog)

## Muestra una línea de diálogo aleatoria de un array de strings
func show_random_dialog(character_name: String, dialog_lines_array: Array) -> void:
	if dialog_lines_array.is_empty():
		print("no hay array de dialogos!ª")
		return
	
	# Seleccionar una línea aleatoria
	var random_index = randi() % dialog_lines_array.size()
	var random_text = dialog_lines_array[random_index]
	
	# Crear una única línea de diálogo
	var formatted_dialog: Array = [character_name, random_text]
	
	# Usar la función existente para mostrar el diálogo
	start_dialog_from_dictionary(formatted_dialog)
# Nueva función set_generic_dialog con dos parámetros
func set_generic_dialog(character_name: String, dialog_lines_array: Array) -> void:
	# Crear el formato que espera start_dialog_from_dictionary
	var formatted_dialog: Array = [character_name]
	formatted_dialog.append_array(dialog_lines_array)
	character_dialog = formatted_dialog

func next_line() -> void:
	if not is_dialog_active:
		return
	
	if is_typing:
		_complete_text()
		return
	
	# avanzar linea
	current_line_index += 1
	
	if current_line_index >= dialog_lines.size():
		_end_dialog()
	else:
		_show_line(current_line_index)

func set_typing_speed(speed: float) -> void:
	typing_speed = max(speed, 0.01)

## Métodos privados

func _show_line(index: int) -> void:
	if index >= dialog_lines.size():
		return
	
	var line = dialog_lines[index]
	
	# handle nombre vacio o nulo
	if line.character_name.is_empty():
		name_label.text = "???"
	else:
		name_label.text = line.character_name
	
	current_text = line.text
	current_char_index = 0
	is_typing = true
	typing_timer = 0.0
	text_label.text = ""
	next_button.disabled = true
	
	dialog_updated.emit(index)

func _process(delta: float) -> void:
	if not is_typing:
		return
	
	typing_timer += delta
	
	if typing_timer >= typing_speed:
		typing_timer = 0.0
		current_char_index += 1
		
		if current_char_index <= current_text.length():
			text_label.text = current_text.substr(0, current_char_index)
			text_label.scroll_to_line(text_label.get_line_count() - 1)
			
			if current_char_index == current_text.length():
				is_typing = false
				next_button.disabled = false

func _complete_text() -> void:
	if is_typing:
		is_typing = false
		text_label.text = current_text
		next_button.disabled = false

func _end_dialog() -> void:
	is_dialog_active = false
	is_typing = false
	visible = false
	hide()
	dialog_lines.clear()
	dialog_finished.emit()

func _on_next_pressed() -> void:
	next_line()
