extends Node

#esto esta mal pero para probar
@warning_ignore("unused_signal")
signal objeto_confiscado

#valores y referencias globales
var is_dragging: bool = false
var drag_limits: Rect2 = Rect2()

## conteo de dias
var current_day: int = 1 #maximo es 6

var items_confiscados:Array = []
var characters_aproved:Array = []
var characters_detained:Array = []
