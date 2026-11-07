## Класс, реализующий логику бассейна.
## Бассейн хранит рыб и определяет своё состояние по параметрам среды.
class_name Pool extends Node3D

enum states {DEFEAT, RECOVERED, STABILISATION, NORMAL}

const TEMPERATURE_TOLERANCE := 2

@export var curent_state: states = states.RECOVERED

@export_group("characteristics")
@export var curent_temperature: int = 20
@export var curent_filtration: float = 0.9
@export var curent_oxygen: float = 0.98
@export var curent_feeding: int = 5

@export var time_stabilization: int = 600

@export_group("dependies")
@export var camera_pos: Marker3D
@export var pool_colision: CollisionShape3D
@export var water: MeshInstance3D
@export var pool_timer: Timer

signal state_change(state: Pool.states)
signal reovered


func _ready() -> void:
	if not is_instance_valid(pool_colision) or not pool_colision.shape is BoxShape3D:
		Core.push_fatal_error("Класс Pool поддерживает только BoxShape3D. Другие виды форм не поддерживаются.")

	if not is_instance_valid(pool_timer):
		push_error("Pool: не назначен pool_timer.")
		return

	pool_timer.one_shot = true
	pool_timer.stop()
	if not pool_timer.timeout.is_connected(_make_stable):
		pool_timer.timeout.connect(_make_stable)

	Core.economy_tools.register_pool(self)
	_update_recovery_state()


func _process(_delta: float) -> void:
	_update_recovery_state()


func _has_valid_parameters() -> bool:
	var temperature_is_valid := (
		curent_temperature >= Fish.REQUIRED_TEMPERATURE - TEMPERATURE_TOLERANCE
		and curent_temperature <= Fish.REQUIRED_TEMPERATURE + TEMPERATURE_TOLERANCE
	)

	return (
		temperature_is_valid
		and curent_filtration >= Fish.REQUIRED_FILTRATION
		and curent_oxygen >= Fish.REQUIRED_OXYGEN
		and curent_feeding >= Fish.REQUIRED_FEEDING
	)


func _update_recovery_state() -> void:
	if curent_state != states.DEFEAT and curent_state != states.RECOVERED:
		return

	var next_state := states.RECOVERED if _has_valid_parameters() else states.DEFEAT
	if next_state == curent_state:
		return

	curent_state = next_state
	state_change.emit(curent_state)


func pick_random_point() -> Vector3:
	var box := pool_colision.shape as BoxShape3D
	var local_point := Vector3(
		randf_range(-box.size.x / 2.0, box.size.x / 2.0),
		randf_range(-box.size.y / 2.0, box.size.y / 2.0),
		randf_range(-box.size.z / 2.0, box.size.z / 2.0)
	)
	return pool_colision.global_transform * local_point


func get_state() -> states:
	return curent_state


func spawn_fish() -> void:
	pass


func start_stabilization() -> void:
	if curent_state != states.RECOVERED:
		return
	if not is_instance_valid(pool_timer):
		push_error("Pool: невозможно начать стабилизацию — pool_timer не назначен.")
		return

	curent_state = states.STABILISATION
	state_change.emit(curent_state)
	pool_timer.start(time_stabilization)


func _make_stable() -> void:
	if curent_state != states.STABILISATION:
		return

	curent_state = states.NORMAL
	state_change.emit(curent_state)
	reovered.emit()


## Снимок состояния бассейна для общего сохранения, управляемого ядром.
func get_save_data() -> Dictionary:
	var remaining := 0.0
	if curent_state == states.STABILISATION and is_instance_valid(pool_timer):
		remaining = pool_timer.time_left

	return {
		"state": int(curent_state),
		"stabilization_remaining": remaining
	}


## Восстанавливает состояние бассейна. Офлайн-время уже вычтено модулем экономики.
func restore_saved_state(saved_state: states, stabilization_remaining: float = 0.0) -> void:
	if is_instance_valid(pool_timer):
		pool_timer.stop()

	if saved_state == states.STABILISATION and stabilization_remaining > 0.0:
		curent_state = states.STABILISATION
		if is_instance_valid(pool_timer):
			pool_timer.start(stabilization_remaining)
	elif saved_state == states.STABILISATION or saved_state == states.NORMAL:
		curent_state = states.NORMAL
	else:
		curent_state = saved_state

	state_change.emit(curent_state)
	if curent_state == states.NORMAL:
		reovered.emit()
