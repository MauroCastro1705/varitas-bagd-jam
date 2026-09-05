class_name DayData extends Resource
## Datos relacionados al nivel/día

@export var day_number: int

## Items permitidos
@export var allowed_rules: Array[ItemRule]
## Items a confiscar
@export var restricted_rules: Array[ItemRule]
## Items que requieren detención del individuo
@export var prohibited_rules: Array[ItemRule]

## Personajes que van a presentarse en ventanilla durante el día, en orden
@export var characters: Array[CharacterData]
