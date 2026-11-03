class_name PoolCamera extends Camera3D

@export var pools: Array[Pool]
@export var swith_speed: float = 1.0
var curent_pool: Pool


func _ready() -> void:
	curent_pool = pools[0]


func _physics_process(delta: float) -> void:
	if curent_pool:
		position = position.move_toward(curent_pool.camera_pos.global_position, swith_speed * delta)
	if Input.is_action_just_pressed("scroll_up"):
		curent_pool = pools[min(pools.find(curent_pool) + 1, len(pools) - 1)]
	if Input.is_action_just_pressed("scroll_down"):
		curent_pool = pools[max(pools.find(curent_pool) - 1, 0)]
