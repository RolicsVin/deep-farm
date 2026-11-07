## Скрипт для изменения состояния бассейна.
extends Control

@export var swipe_min_distance: float = 80.0
@export var slide_time: float = 0.35
@export var recovy_button: Button

var pool: Pool

var _shown := false
var _tween: Tween
var _swipe_start := Vector2.ZERO
var _swiping := false
var _sliders: Array[Node]


func _ready() -> void:
	_sliders = find_children("*", "Slider", true, false)
	position.x = _hidden_x()
	resized.connect(_snap)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.canceled:
			_swiping = false
		elif event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe(event.position)


func slide_in() -> void:
	if _shown:
		return
	_shown = true
	_move_to(0.0)


func slide_out() -> void:
	if not _shown:
		return
	_shown = false
	_move_to(_hidden_x())


func _begin_swipe(pos: Vector2) -> void:
	_swiping = not _is_over_slider(pos)
	_swipe_start = pos


func _end_swipe(pos: Vector2) -> void:
	if not _swiping:
		return
	_swiping = false

	var delta := pos - _swipe_start
	if absf(delta.x) < swipe_min_distance or absf(delta.x) < absf(delta.y):
		return

	if delta.x > 0.0:
		slide_in()
	else:
		slide_out()


func _is_over_slider(pos: Vector2) -> bool:
	for slider in _sliders:
		if is_instance_valid(slider) and (slider as Control).get_global_rect().has_point(pos):
			return true
	return false


func is_point_over_panel(pos: Vector2) -> bool:
	var panel := get_node_or_null("Panel") as Control
	return _shown and panel != null and panel.get_global_rect().has_point(pos)


func _hidden_x() -> float:
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


func set_pool(_pool: Pool) -> void:
	# Отключаем обновление от предыдущего бассейна, только если связь существует.
	if is_instance_valid(pool) and pool.state_change.is_connected(update_ui):
		pool.state_change.disconnect(update_ui)

	pool = _pool
	if not is_instance_valid(pool):
		update_ui()
		return

	if not pool.state_change.is_connected(update_ui):
		pool.state_change.connect(update_ui)

	update_ui()


func update_ui(_state = null) -> void:
	if not is_instance_valid(pool):
		return
	update_states()
	chech_pool_state()


func update_states() -> void:
	$Panel/VBoxContainer/t.set_value_no_signal(pool.curent_temperature)
	$Panel/VBoxContainer/filter.set_value_no_signal(pool.curent_filtration * 100.0)
	$Panel/VBoxContainer/o.set_value_no_signal(pool.curent_oxygen * 100.0)
	$Panel/VBoxContainer/feething.set_value_no_signal(pool.curent_feeding)

	var is_editable := pool.get_state() == Pool.states.DEFEAT
	$Panel/VBoxContainer/t.editable = is_editable
	$Panel/VBoxContainer/filter.editable = is_editable
	$Panel/VBoxContainer/o.editable = is_editable
	$Panel/VBoxContainer/feething.editable = is_editable


func set_temperature(t: float) -> void:
	if is_instance_valid(pool):
		pool.curent_temperature = int(t)


func set_filtration(f: float) -> void:
	if is_instance_valid(pool):
		pool.curent_filtration = f / 100.0


func set_oxygen(o: float) -> void:
	if is_instance_valid(pool):
		pool.curent_oxygen = o / 100.0


func set_feeding(f: float) -> void:
	if is_instance_valid(pool):
		pool.curent_feeding = int(f)


func recove() -> void:
	if not is_instance_valid(pool):
		return
	pool.start_stabilization()
	update_ui()


func chech_pool_state() -> void:
	if not is_instance_valid(recovy_button):
		return

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
