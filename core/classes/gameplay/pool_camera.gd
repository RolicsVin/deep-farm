class_name PoolCamera extends Camera3D

@export var pools: Array[Pool]
@export var swith_speed: float = 1.0
@export var swipe_min_distance: float = 80.0  # минимальная длина свайпа в пикселях
@export var ui: Control ## Пользовательский интерфейс для редактирования бассейна

var curent_pool: Pool
var _swipe_start := Vector2.ZERO
var _swiping := false


func _ready() -> void:
	if pools.is_empty():
		push_error("PoolCamera: массив pools пуст.")
		return

	curent_pool = pools[0]
	if is_instance_valid(ui):
		ui.set_pool(curent_pool)


func _physics_process(delta: float) -> void:
	if is_instance_valid(curent_pool) and is_instance_valid(curent_pool.camera_pos):
		global_position = global_position.move_toward(
			curent_pool.camera_pos.global_position,
			swith_speed * delta
		)


func _unhandled_input(event: InputEvent) -> void:
	# Сенсорный экран
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.canceled:
			_swiping = false
		elif event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)

	# Левая кнопка мыши — тестирование свайпов на ПК
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)


func _begin_swipe(pos: Vector2) -> void:
	_swipe_start = pos
	# Вертикальный жест над меню не должен переключать бассейны.
	_swiping = not (is_instance_valid(ui) and ui.is_point_over_panel(pos))


func _end_swipe(pos: Vector2) -> void:
	if not _swiping:
		return
	_swiping = false

	var delta := pos - _swipe_start
	# Переключение бассейнов работает только при преимущественно вертикальном свайпе.
	if absf(delta.y) < swipe_min_distance or absf(delta.y) < absf(delta.x):
		return

	if delta.y < 0.0:
		_switch_pool(1)  # свайп вверх -> следующий бассейн
	else:
		_switch_pool(-1) # свайп вниз -> предыдущий бассейн


func _switch_pool(step: int) -> void:
	if pools.is_empty():
		return

	var current_index := pools.find(curent_pool)
	var next_index := clampi(current_index + step, 0, pools.size() - 1)
	if next_index == current_index:
		return

	curent_pool = pools[next_index]
	if is_instance_valid(ui):
		ui.set_pool(curent_pool)
