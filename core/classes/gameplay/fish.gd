## Класс рыб.
## Реализует поведение рыбы и хранит параметры её жизнеспособности.
class_name Fish extends Entitie

const REQUIRED_TEMPERATURE = 20
const REQUIRED_FILTRATION = 0.9
const REQUIRED_OXYGEN = 0.98
const REQUIRED_FEEDING = 5

enum states {NORMAl, DAMAGET, DEAD}
var current_state = states.NORMAl

@export var brain_timer: Timer
@export var pool: Pool
@export var money: int

# Точка назначения хранится в глобальных координатах.
var next_pos: Vector3


func _ready() -> void:
	# Если бассейн не назначен в инспекторе, получаем его от родителя.
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

	# До первого выбора рыба остаётся на месте, а не плывёт к Vector3.ZERO.
	next_pos = global_position

	brain_timer.wait_time = randf_range(5.0, 10.0)
	brain_timer.one_shot = true
	if not brain_timer.timeout.is_connected(choise):
		brain_timer.timeout.connect(choise)
	brain_timer.start(1.0)


func update_state() -> void: ## Обновляет состояние рыбы.
	var counter: int = 0

	if pool.curent_temperature < REQUIRED_TEMPERATURE:
		counter += 1
	if pool.curent_filtration < REQUIRED_FILTRATION:
		counter += 1
	if pool.curent_oxygen < REQUIRED_OXYGEN:
		counter += 1
	if pool.curent_feeding < REQUIRED_FEEDING:
		counter += 1

	if counter == 0:
		current_state = states.NORMAl
	elif counter == 1:
		current_state = states.DAMAGET
	else:
		current_state = states.DEAD


func _physics_process(delta: float) -> void:
	if not is_instance_valid(pool):
		return

	update_state()
	fish_logic(delta)


func fish_logic(delta: float) -> void:
	match current_state:
		states.NORMAl:
			global_position = global_position.move_toward(next_pos, speed * delta)

		states.DAMAGET:
			global_position = global_position.move_toward(next_pos, (speed / 2.0) * delta)

		states.DEAD:
			# Верхняя точка коллайдера с учётом его поворота и масштаба.
			var shape := pool.pool_colision.shape as BoxShape3D
			var surface_local := Vector3(0.0, shape.size.y / 2.0, 0.0)
			var surface_global := pool.pool_colision.global_transform * surface_local
			global_position.y = move_toward(
				global_position.y,
				surface_global.y,
				(speed / 2.0) * delta
			)


func choise() -> void:
	if not is_instance_valid(pool):
		return

	# pool.pick_random_point() возвращает глобальную точку именно этого бассейна.
	next_pos = pool.pick_random_point()
	brain_timer.start(randf_range(5.0, 10.0))
