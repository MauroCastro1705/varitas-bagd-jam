extends Node2D
@onready var dia_label: Label = $dia
@onready var fecha_label: Label = $fecha

# Array de diccionarios con las fechas
var lista_fechas = [
	{"fecha": "24 de agosto de 2026", "dia": "Lunes - Dia 1"},
	{"fecha": "25 de agosto de 2026", "dia": "Martes - Dia 2"},
	{"fecha": "26 de agosto de 2026", "dia": "Miercoles - Dia 3"},
	{"fecha": "27 de agosto de 2026", "dia": "Jueves - Dia 4"},
	{"fecha": "28 de agosto de 2026", "dia": "Viernes - Dia 5"},
	{"fecha": "29 de agosto de 2026", "dia": "Sabado - Dia 6"},
	{"fecha": "30 de agosto de 2026", "dia": "Domingo - Dia 7"}
]

var indice_actual:int
var fecha_texto:String = ""
var dia_texto:String = ""

func _ready():
	indice_actual = (Global.current_day - 1) #a chequear jaja
	obtener_par_actual()
	_actualizar_labels()

func obtener_par_actual():
	print("dia actual " , indice_actual)
	if indice_actual < lista_fechas.size():
		var par = lista_fechas[indice_actual]
		fecha_texto = par["fecha"]#asignamos los valores a cada variable
		dia_texto = par["dia"]
		return par
	return null

func _actualizar_labels() -> void:
	dia_label.text = fecha_texto
	fecha_label.text = dia_texto

func _on_timer_timeout() -> void:
	TransitionManager.change_scene("res://escenas/game_scene/main_game.tscn")
