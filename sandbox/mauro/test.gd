extends Node

@onready var item_spawner: ItemSpawner = $ItemSpawner
const ANILLO = preload("uid://cb3ktssmlo4sp")
const LIBRO = preload("uid://ccdyabnd31k8i")
const TREBOL = preload("uid://wvig3bypj8br")

var items_to_spawn: Array[ItemData] = [
		ANILLO,
		LIBRO,
		TREBOL
	]
	

func _ready():
	spawn_new_items()


func spawn_new_items():
	# Conectar señales
	item_spawner.all_items_spawned.connect(_on_all_items_spawned)
	item_spawner.item_spawned.connect(_on_item_spawned)
	
	# Spawnear
	item_spawner.spawn_items(items_to_spawn)

func _on_all_items_spawned():
	print("¡Todos los items han sido spawnados!")

func _on_item_spawned(item: Item):
	print("Item spawnado: ", item.data.item_name)
