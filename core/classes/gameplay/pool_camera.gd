class_name PoolCamera extends Camera3D

@export var pools: Array[Pool]
@export var swith_speed: float = 1.0
@export var swipe_min_distance: float = 80.0  # минимальная длина свайпа в пикселях
@export var ui: Control ## Ползовательский интерфейс, для редактирования бассейна
var curent_pool: Pool

var _swipe_start := Vector2.ZERO
var _swiping := false


func _ready() -> void:
	curent_pool = pools[0]
	ui.set_pool(curent_pool)


func _physics_process(delta: float) -> void:
	if curent_pool:
		global_position = global_position.move_toward(curent_pool.camera_pos.global_position, swith_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	# Тач
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)
	# Мышь (для теста на ПК)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)


func _begin_swipe(pos: Vector2) -> void:
	_swipe_start = pos
	_swiping = true


func _end_swipe(pos: Vector2) -> void:
	if not _swiping:
		return
	_swiping = false
	var delta := pos - _swipe_start
	# Свайп должен быть в основном горизонтальным и достаточно длинным
	if absf(delta.x) < swipe_min_distance or absf(delta.x) < absf(delta.y):
		return
	if delta.x < 0.0:
		_switch_pool(1)   # свайп влево -> следующий бассейн
	else:
		_switch_pool(-1)  # свайп вправо -> предыдущий


func _switch_pool(step: int) -> void:
	var i := clampi(pools.find(curent_pool) + step, 0, pools.size() - 1)
	curent_pool = pools[i]
	ui.set_pool(curent_pool)
