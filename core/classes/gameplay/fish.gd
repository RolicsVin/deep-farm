## Класс рыб.
## Реализует поведение рыбы и визуально отображает состояние бассейна.
class_name Fish extends Entitie

const REQUIRED_TEMPERATURE = 20
const TEMPERATURE_TOLERANCE = 2
const REQUIRED_FILTRATION = 0.9
const REQUIRED_OXYGEN = 0.98
const REQUIRED_FEEDING = 5

const HEALTHY_COLOR := Color.WHITE
const COLD_COLOR := Color(0.25, 0.55, 1.0)
const HOT_COLOR := Color(1.0, 0.2, 0.15)

enum states {NORMAl, DAMAGET, DEAD}
var current_state = states.NORMAl

@export var brain_timer: Timer
@export var pool: Pool
@export var money: int
@export var fish_mesh: MeshInstance3D

var next_pos: Vector3
var fish_material: StandardMaterial3D

const SURFACE_SPEED_MULTIPLIER := 0.1
const TURN_SPEED := 4.0


func _ready() -> void:
	if not is_instance_valid(pool):
		pool = get_parent() as Pool

	if not is_instance_valid(pool):
		push_error("Fish: не назначен бассейн (pool).")
		set_physics_process(false)
		return

	if not is_instance_valid(brain_timer):
		push_error("Fish: не назначен brain_timer.")
		set_physics_process(false)
		return

	if not is_instance_valid(fish_mesh):
		fish_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D

	if is_instance_valid(fish_mesh):
		var source_material := fish_mesh.get_active_material(0) as StandardMaterial3D
		if is_instance_valid(source_material):
			fish_material = source_material.duplicate() as StandardMaterial3D
			fish_mesh.material_override = fish_material

	next_pos = global_position

	brain_timer.wait_time = randf_range(5.0, 10.0)
	brain_timer.one_shot = true
	if not brain_timer.timeout.is_connected(choise):
		brain_timer.timeout.connect(choise)
	brain_timer.start(1.0)


func update_state() -> void:
	var has_problem := (
		pool.curent_temperature < REQUIRED_TEMPERATURE - TEMPERATURE_TOLERANCE
		or pool.curent_temperature > REQUIRED_TEMPERATURE + TEMPERATURE_TOLERANCE
		or pool.curent_filtration < REQUIRED_FILTRATION
		or pool.curent_oxygen < REQUIRED_OXYGEN
		or pool.curent_feeding < REQUIRED_FEEDING
	)

	# По концепции игры проблемы среды ухудшают состояние рыб,
	# но не приводят к их гибели.
	current_state = states.DAMAGET if has_problem else states.NORMAl


func update_appearance() -> void:
	if not is_instance_valid(fish_material):
		return

	if pool.curent_temperature < REQUIRED_TEMPERATURE - TEMPERATURE_TOLERANCE:
		fish_material.albedo_color = COLD_COLOR
	elif pool.curent_temperature > REQUIRED_TEMPERATURE + TEMPERATURE_TOLERANCE:
		fish_material.albedo_color = HOT_COLOR
	else:
		fish_material.albedo_color = HEALTHY_COLOR


func _physics_process(delta: float) -> void:
	if not is_instance_valid(pool):
		return

	update_state()
	update_appearance()
	fish_logic(delta)


func fish_logic(delta: float) -> void:
	var movement_speed := speed

	# Недостаточная фильтрация делает рыб вялыми.
	if pool.curent_filtration < REQUIRED_FILTRATION:
		movement_speed *= 0.35

	var target := next_pos

	# При нехватке кислорода рыба всплывает и затем медленно дрейфует
	# у поверхности, словно пассивно плавающее тело.
	if pool.curent_oxygen < REQUIRED_OXYGEN:
		var box := pool.pool_colision.shape as BoxShape3D
		var surface_local := Vector3(0.0, box.size.y / 2.0, 0.0)
		var surface_global := pool.pool_colision.global_transform * surface_local
		target = Vector3(next_pos.x, surface_global.y - 0.08, next_pos.z)
		movement_speed *= SURFACE_SPEED_MULTIPLIER
	elif current_state == states.DAMAGET:
		movement_speed *= 0.5

	var movement := target - global_position
	if movement.length_squared() > 0.0001:
		# Модель рыбы вытянута вдоль локальной оси X, поэтому
		# разворачиваем её продольную ось по горизонтальному направлению движения.
		var horizontal_direction := Vector2(movement.x, movement.z)
		if horizontal_direction.length_squared() > 0.0001:
			var target_rotation := atan2(-horizontal_direction.y, horizontal_direction.x)
			rotation.y = rotate_toward(rotation.y, target_rotation, TURN_SPEED * delta)

	global_position = global_position.move_toward(target, movement_speed * delta)


func choise() -> void:
	if not is_instance_valid(pool):
		return

	next_pos = pool.pick_random_point()
	brain_timer.start(randf_range(5.0, 10.0))
