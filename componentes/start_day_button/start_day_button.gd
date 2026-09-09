extends Button
@onready var nine_patch_rect: NinePatchRect = $NinePatchRect
@onready var label: Label = $Label
@onready var hover: NinePatchRect = $hover

func _ready() -> void:
	hover.hide()
	nine_patch_rect.self_modulate = Color(0.663, 0.663, 0.663)	


func _on_mouse_entered() -> void:
	hover.show()
	nine_patch_rect.self_modulate = Color(1,1,1,1)
	
func _on_mouse_exited() -> void:
	hover.hide()
	nine_patch_rect.self_modulate = Color(0.663, 0.663, 0.663)
	
