class_name ItemRule extends Resource

@export var rule_name: String
@export var required_tags: Array[ItemTags.Tag]


## Recibe un item y devuelve si cumple o no la regla
func matches(item: ItemData) -> bool:
	if required_tags.is_empty(): return false

	for tag in required_tags:
		# Chequea que cada tag requerida esté presente en el item a validar
		if not item.tags.has(tag):
			return false # Si no encontró al menos una, ya no es match
	# Si encontró todas, es un match total
	return true
