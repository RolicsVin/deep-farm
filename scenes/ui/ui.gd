## Скрипт для изменения состояние бассейна. 
extends Control


@export var swipe_min_distance: float = 80.0 ## Минимальная длина свайпа в пикселях
@export var slide_time: float = 0.35 ## Длительность анимации панели в секундах

var pool: Pool

var _shown := false ## Опущена ли панель сейчас
var _tween: Tween
var _swipe_start := Vector2.ZERO
var _swiping := false
var _sliders: Array[Node] ## Слайдеры панели - на них свайпы и колесо не реагируют


func _ready() -> void:
	_sliders = find_children("*", "Slider", true, false)
	# Поднимаем инструменты выше экрана
	position.y = _hidden_y()
	# При изменении размера окна anchors сбросят позицию - возвращаем её
	resized.connect(_snap)


func _input(event: InputEvent) -> void:
	# Колесо мыши: вниз - опустить панель, вверх - поднять
	if event is InputEventMouseButton:
		if event.is_action_pressed("scroll_down"):
			if not _is_over_slider(event.position):
				slide_in()
			return
		if event.is_action_pressed("scroll_up"):
			if not _is_over_slider(event.position):
				slide_out()
			return
	
	# Тач
	if event is InputEventScreenTouch:
		if event.index != 0: # Только первый палец
			return
		if event.canceled:
			_swiping = false
		elif event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)
	# Мышь (зажать ЛКМ и потянуть - работает на ПК)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)


func slide_in() -> void: ## Опустит панель (покажет)
	if _shown:
		return
	_shown = true
	_move_to(0.0)


func slide_out() -> void: ## Поднимет панель выше экрана (спрячет)
	if not _shown:
		return
	_shown = false
	_move_to(_hidden_y())


func _begin_swipe(pos: Vector2) -> void:
	# Если нажали на слайдер - это не свайп панели, а настройка значения
	_swiping = not _is_over_slider(pos)
	_swipe_start = pos


func _end_swipe(pos: Vector2) -> void:
	if not _swiping:
		return
	_swiping = false
	var delta := pos - _swipe_start
	# Свайп должен быть в основном вертикальным и достаточно длинным
	if absf(delta.y) < swipe_min_distance or absf(delta.y) < absf(delta.x):
		return
	if delta.y > 0.0:
		slide_in()  # свайп вниз -> опускаем панель
	else:
		slide_out() # свайп вверх -> поднимаем панель


func _is_over_slider(pos: Vector2) -> bool:
	for s in _sliders:
		if (s as Control).get_global_rect().has_point(pos):
			return true
	return false


func _hidden_y() -> float: 
	# Высота именно игрового окна (viewport), а не физического монитора
	return -get_viewport_rect().size.y


func _move_to(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", target_y, slide_time)


func _snap() -> void:
	if _tween:
		_tween.kill()
	position.y = 0.0 if _shown else _hidden_y()


func set_pool(_pool: Pool) -> void: ## Установит бассейн для редактирвоания
	pool = _pool
	
	# Установка значений
	$Panel/VBoxContainer/t.value = pool.curent_temperature
	$Panel/VBoxContainer/filter.value = pool.curent_filtration
	$Panel/VBoxContainer/o.value = pool.curent_oxygen
	$Panel/VBoxContainer/feething.value = pool.curent_feeding


func set_temperature(t: int): ## Установит температуру для текущего бассейна
	pool.curent_temperature = int(t)


func set_filtration(f: float): ## Установит фильтрацию для текущего бассейна
	pool.curent_filtration = f / 100


func set_oxygen(o: float): ## Установит кислород для текущего бассейна
	pool.curent_oxygen = o / 100


func set_feeding(f: int): ## Установит кормление для текущего бассейна
	pool.curent_feeding = int(f)
