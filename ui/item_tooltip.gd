extends PanelContainer


@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel

var offset: Vector2 = Vector2(50, -50) # Offset por default, arriba y a la derecha


func _ready() -> void:
	hide()


func _on_item_tooltip_requested(data: ItemData, item_pos: Vector2):
	name_label.text = data.item_name
	desc_label.text = data.item_description

	show()

	# Esperar 1 frame para que se recalcule el tamaño del PanelContainer en base al nuevo texto
	await get_tree().process_frame

	var target_pos = item_pos + offset

	var screen_size = get_viewport_rect().size
	if target_pos.x + self.size.x > screen_size.x:
		target_pos.x = item_pos.x - self.size.x - offset.x

	if target_pos.y < 0:
		target_pos.y = 10

	self.global_position = target_pos


func _on_item_tooltip_hidden():
	hide()
	name_label.text = ""
	desc_label.text = ""
