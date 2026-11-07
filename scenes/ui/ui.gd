## Скрипт для изменения состояния бассейна.
extends Control


@export var swipe_min_distance: float = 80.0 ## Минимальная длина свайпа в пикселях
@export var slide_time: float = 0.35 ## Длительность анимации панели в секундах

@export var recovy_button: Button ## Кнопка, которая запускает восстановление бассейна

var pool: Pool

var _shown := false ## Открыта ли панель сейчас
var _tween: Tween
var _swipe_start := Vector2.ZERO
var _swiping := false
var _sliders: Array[Node] ## Слайдеры панели — взаимодействие с ними не считается свайпом панели


func _ready() -> void:
	_sliders = find_children("*", "Slider", true, false)
	# Изначально скрываем панель за левой границей окна.
	position.x = _hidden_x()
	# При изменении размера окна корректируем положение панели.
	resized.connect(_snap)


func _input(event: InputEvent) -> void:
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


func slide_in() -> void: ## Показывает панель, выдвигая её слева направо.
	if _shown:
		return
	_shown = true
	_move_to(0.0)


func slide_out() -> void: ## Скрывает панель, убирая её вправо-налево.
	if not _shown:
		return
	_shown = false
	_move_to(_hidden_x())


func _begin_swipe(pos: Vector2) -> void:
	# Перетаскивание слайдера не должно открывать или закрывать панель.
	_swiping = not _is_over_slider(pos)
	_swipe_start = pos


func _end_swipe(pos: Vector2) -> void:
	if not _swiping:
		return
	_swiping = false

	var delta := pos - _swipe_start
	# Панель реагирует только на преимущественно горизонтальные свайпы.
	if absf(delta.x) < swipe_min_distance or absf(delta.x) < absf(delta.y):
		return

	if delta.x > 0.0:
		slide_in()  # свайп вправо -> показать панель
	else:
		slide_out() # свайп влево -> скрыть панель


func _is_over_slider(pos: Vector2) -> bool:
	for slider in _sliders:
		if is_instance_valid(slider) and (slider as Control).get_global_rect().has_point(pos):
			return true
	return false


func is_point_over_panel(pos: Vector2) -> bool:
	# Используется камерой, чтобы вертикальный свайп по меню
	# не переключал бассейн под ним.
	var panel := get_node_or_null("Panel") as Control
	return _shown and panel != null and panel.get_global_rect().has_point(pos)


func _hidden_x() -> float:
	# Ширина игрового окна, а не физического монитора.
	return -get_viewport_rect().size.x


func _move_to(target_x: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", target_x, slide_time)


func _snap() -> void:
	if _tween:
		_tween.kill()
	position.x = 0.0 if _shown else _hidden_x()


func set_pool(_pool: Pool) -> void: ## Устанавливает бассейн для редактирования.
	if pool:
		pool.state_change.disconnect(update_ui)

	pool = _pool
	pool.state_change.connect(update_ui)

	update_ui()


func update_ui(_args=null) -> void: ## Обновляет интерфейс.
	update_states()
	chech_pool_state()


func update_states() -> void: ## Обновляет состояние ползунков.
	$Panel/VBoxContainer/t.value = pool.curent_temperature
	$Panel/VBoxContainer/filter.value = pool.curent_filtration * 100
	$Panel/VBoxContainer/o.value = pool.curent_oxygen * 100
	$Panel/VBoxContainer/feething.value = pool.curent_feeding

	# Если бассейн не разрушен, ползунки заблокированы.
	var is_editable := pool.get_state() == Pool.states.DEFEAT
	$Panel/VBoxContainer/t.editable = is_editable
	$Panel/VBoxContainer/filter.editable = is_editable
	$Panel/VBoxContainer/o.editable = is_editable
	$Panel/VBoxContainer/feething.editable = is_editable


func set_temperature(t: int) -> void: ## Устанавливает температуру текущего бассейна.
	pool.curent_temperature = int(t)


func set_filtration(f: float) -> void: ## Устанавливает фильтрацию текущего бассейна.
	pool.curent_filtration = f / 100


func set_oxygen(o: float) -> void: ## Устанавливает кислород текущего бассейна.
	pool.curent_oxygen = o / 100


func set_feeding(f: int) -> void: ## Устанавливает кормление текущего бассейна.
	pool.curent_feeding = int(f)


func recove() -> void: ## Запускает восстановление бассейна.
	pool.start_stabilization()
	chech_pool_state()


func chech_pool_state() -> void: ## Проверяет состояние бассейна и настраивает кнопку.
	match pool.curent_state:
		Pool.states.DEFEAT:
			recovy_button.disabled = true
			recovy_button.text = "Восстановление невозможно: проверьте параметры бассейна"

		Pool.states.RECOVERED:
			recovy_button.disabled = false
			recovy_button.text = "Можно начинать стабилизацию"

		Pool.states.STABILISATION:
			recovy_button.disabled = true
			recovy_button.text = "Восстанавливается..."

		Pool.states.NORMAL:
			recovy_button.disabled = true
			recovy_button.text = "Уже восстановлено"
