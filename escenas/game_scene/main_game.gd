extends Node2D

##dialogos para todos los personajes
var DialogosGenericos = preload("uid://dgc4uon7a5meq")
var dialogos = DialogosGenericos.new()
var dialogo_admision = dialogos.dialogo_admision
var dialogo_confiscado = dialogos.dialogo_confiscacion
var dialogo_detencion = dialogos.dialogo_detencion

## Datos propios del día actual
var cur_char_list: Array[CharacterData] = []
var cur_allowed_rules: Array[ItemRule]
var cur_restricted_rules: Array[ItemRule]
var cur_prohibited_rules: Array[ItemRule]

## Quién está actualmente en ventanilla
var cur_visitor: CharacterData

## Estados del flujo
enum DialogState {
	IDLE,           # Esperando inicio del día
	INITIAL_DIALOG, # Mostrando diálogo inicial
	WAITING_ACTION, # Esperando que el jugador decida (botones habilitados)
	FINAL_DIALOG,   # Mostrando diálogo final
	TRANSITION      # Transición entre personajes
}

var current_state: DialogState = DialogState.IDLE

##NODOS
@onready var item_spawner: ItemSpawner = %ItemSpawner
@onready var accept_button: Button = $ActionButtons/AcceptButton
@onready var detain_button: Button = $ActionButtons/DetainButton
@onready var start_day_button: Button = $start_day_button

@onready var npc: Character = %NPC
@onready var DIALOGOS: DialogScene = $Dialogos
@onready var dialog_timer: Timer = $Dialog_timer
@onready var tooltip = $HUD/ItemTooltip
@onready var fila_de_gente: Label = $fila_de_gente
## Nodo de Control que marca los límites 2D para mover Items, se recarga con el nivel
@onready var desk_bounds: ReferenceRect = %DeskBounds

var day_ended:bool = false
var is_processing_action: bool = false  # Para evitar múltiples clics


func _ready():
	# Set desk bounds for item interaction
	Global.drag_limits = desk_bounds.get_global_rect()
	_set_up_connections()
	_load_day_data()
	_update_label()
	_set_buttons_enabled(false)  # Todos los botones deshabilitados inicialmente
	npc.hide()


func _load_day_data() -> void:
	var cur_day_path: String = "res://levels/day_" + str(int(Global.current_day)) + ".tres"
	var cur_day: DayData = load(cur_day_path)
	if not cur_day:
		push_error("Error al cargar día: " + cur_day_path)
		return

	cur_char_list = cur_day.characters
	cur_allowed_rules = cur_day.allowed_rules
	cur_restricted_rules = cur_day.restricted_rules
	cur_prohibited_rules = cur_day.prohibited_rules
	
	#helpers
	start_day_button.disabled = false
	start_day_button.show()
	npc.hide()
	current_state = DialogState.IDLE


func _start_day() -> void:
	print("en fila: " + str(cur_char_list.size()))
	_set_character_data(get_next_character())
	_set_buttons_enabled(false)  # Deshabilitar botones durante el diálogo inicial


func get_next_character():
	cur_visitor = cur_char_list.pop_front()
	return cur_visitor


func _set_character_data(char_data: CharacterData) -> void:
	if not char_data: 
		no_character_left()
		return

	npc.data = char_data
	npc.sprite_2d.texture = char_data.sprite
	dialog_timer.start() #para que no aparezca de golpe el dialogo


func _set_up_connections() -> void:
	Global.objeto_confiscado.connect(_update_label)
	DIALOGOS.dialog_finished.connect(_on_dialog_finished)
	item_spawner.item_spawned.connect(_on_item_spawned)
	


func no_character_left() -> void:
	fila_de_gente.text = "Se termino el dia"
	npc.queue_free()
	day_ended = true
	print("termino el dia")
	_set_buttons_enabled(false)
	current_state = DialogState.IDLE
	#llamar a end_day?


func _on_dialog_timer_timeout() -> void:
	# para que el dialogo se dispare unos segundos despues que la imagen del char
	begin_initial_dialog()


func begin_initial_dialog():
	current_state = DialogState.INITIAL_DIALOG
	var dialogo = npc.data.dialog
	var nombre = npc.data.name
	DIALOGOS.set_generic_dialog(nombre, dialogo)
	DIALOGOS.start_generic_dialog()
	_set_buttons_enabled(false)  # Deshabilitar durante el diálogo


func begin_final_dialog(action: String):
	current_state = DialogState.FINAL_DIALOG
	var nombre:String = npc.data.name
	_set_buttons_enabled(false)  # Deshabilitar durante el diálogo final
	
	if action == "detained":
		print(nombre, " fue detenido")
		DIALOGOS.show_random_dialog(nombre, dialogo_detencion)
	elif action == "accepted":
		print(nombre, " fue aceptado")
		DIALOGOS.show_random_dialog(nombre, dialogo_admision)


func _on_dialog_finished():
	match current_state:
		DialogState.INITIAL_DIALOG:
			# Terminó el diálogo inicial, habilitar botones
			current_state = DialogState.WAITING_ACTION
			spawn_items_in_scene()
			_set_buttons_enabled(true)
			
		DialogState.FINAL_DIALOG:
			# Terminó el diálogo final, pasar al siguiente personaje
			current_state = DialogState.TRANSITION
			# Limpiar items y preparar siguiente personaje
			clear_all_items()
			clear_list()
			_update_label()
			# Cargar siguiente personaje
			_set_character_data(get_next_character())
			
		_:
			# Por si acaso
			pass


func spawn_items_in_scene():
	var item_list = npc.data.item_list
	item_spawner.spawn_items(item_list)


## Funciones de control de botones
func _set_buttons_enabled(enabled: bool) -> void:
	if not day_ended:
		accept_button.disabled = !enabled
		detain_button.disabled = !enabled
	else:
		accept_button.disabled = true
		detain_button.disabled = true


##updates visuales
func _update_label():
	fila_de_gente.text = "Magos en la fila: " + str(cur_char_list.size())


func clear_all_items() -> void:
	var items = get_tree().get_nodes_in_group("items")
	for item in items:
		if is_instance_valid(item):
			item.queue_free()


# LOGICA ACEPTADO O DEPORTADO
func _on_accept_button_pressed() -> void:
	if not day_ended and current_state == DialogState.WAITING_ACTION and not is_processing_action:
		is_processing_action = true
		_set_buttons_enabled(false)  # Deshabilitar inmediatamente
		
		Global.characters_aproved.append(npc.data.name)
		print("aprobados: " , Global.characters_aproved)
		print("en fila: " + str(cur_char_list.size()))
		
		# Limpiar items (opcional, se hace en la transición)
		clear_all_items()
		
		# Mostrar diálogo final
		begin_final_dialog("accepted")


func _on_detain_button_pressed() -> void:
	if not day_ended and current_state == DialogState.WAITING_ACTION and not is_processing_action:
		is_processing_action = true
		_set_buttons_enabled(false)  # Deshabilitar inmediatamente
		
		Global.characters_detained.append(npc.data.name)
		print("detenidos: " , Global.characters_detained)
		print("en fila: " + str(cur_char_list.size()))
		
		# Limpiar items (opcional, se hace en la transición)
		clear_all_items()
		
		# Mostrar diálogo final
		begin_final_dialog("detained")


func _on_item_spawned(item: Item) -> void:
	item.tooltip_requested.connect(tooltip._on_item_tooltip_requested)
	item.tooltip_hidden.connect(tooltip._on_item_tooltip_hidden)


func clear_list(): #solo para debug
	Global.items_confiscados = []


## Función tentativa para avanzar los días al terminar la jornada
func _end_day() -> void:
	Global.current_day += 1
	TransitionManager.change_scene("res://escenas/day_scene/nuevo_dia.tscn")


func _on_start_day_button_pressed() -> void:
	_start_day()
	npc.show()
	start_day_button.disabled = true
	start_day_button.hide()
