## Модуль экономики. Создаётся ядром через Core._make_tool().
class_name EconomyTools extends Node

signal updated(balance: int, pending_income: int, income_per_minute: float)
signal offline_income_received(amount: int)

const SAVE_PATH := "user://economy_data.tres"
const SAVE_INTERVAL := 15.0

var data: EconomyData = EconomyData.new()
var _registered_pools: Array[Pool] = []
var _save_elapsed: float = 0.0
var _fractional_income: float = 0.0

var balance: int:
	get:
		return data.balance

var pending_income: int:
	get:
		return data.pending_income

var income_per_minute: float:
	get:
		return data.income_per_minute

var offline_income: int:
	get:
		return data.offline_income


func _ready() -> void:
	_load_data()
	_apply_offline_income()
	updated.emit(balance, pending_income, income_per_minute)


func _process(delta: float) -> void:
	if income_per_minute > 0.0:
		_fractional_income += income_per_minute * delta / 60.0
		var whole_income := int(floor(_fractional_income))
		if whole_income > 0:
			data.pending_income += whole_income
			_fractional_income -= whole_income
			updated.emit(balance, pending_income, income_per_minute)

	_save_elapsed += delta
	if _save_elapsed >= SAVE_INTERVAL:
		_save_elapsed = 0.0
		_save_data()


func register_pool(pool: Pool) -> void:
	if not is_instance_valid(pool) or _registered_pools.has(pool):
		return
	_registered_pools.append(pool)
	if not pool.state_change.is_connected(_on_pool_state_changed):
		pool.state_change.connect(_on_pool_state_changed.bind(pool))
	pool.tree_exiting.connect(unregister_pool.bind(pool))

	var pool_path := str(pool.get_path())
	if data.automated_pool_paths.has(pool_path):
		pool.curent_state = Pool.states.NORMAL
	_recalculate_income()


func unregister_pool(pool: Pool) -> void:
	_registered_pools.erase(pool)
	_recalculate_income()


func _on_pool_state_changed(state: Pool.states, pool: Pool) -> void:
	var pool_path := str(pool.get_path())
	if state == Pool.states.NORMAL:
		if not data.automated_pool_paths.has(pool_path):
			data.automated_pool_paths.append(pool_path)
	else:
		data.automated_pool_paths.erase(pool_path)
	_recalculate_income()
	_save_data()


func _recalculate_income() -> void:
	var new_income := 0.0
	for pool in _registered_pools:
		if not is_instance_valid(pool) or pool.get_state() != Pool.states.NORMAL:
			continue
		for child in pool.get_children():
			if child is Fish:
				new_income += maxi(0, child.money)
	data.income_per_minute = new_income
	updated.emit(balance, pending_income, income_per_minute)


func collect_income() -> int:
	var collected := pending_income
	if collected <= 0:
		return 0
	data.balance += collected
	data.pending_income = 0
	updated.emit(balance, pending_income, income_per_minute)
	_save_data()
	return collected


func _apply_offline_income() -> void:
	var now := int(Time.get_unix_time_from_system())
	if data.last_saved_at <= 0:
		data.last_saved_at = now
		return
	var elapsed := maxi(0, now - data.last_saved_at)
	var earned := int(floor(elapsed * income_per_minute / 60.0))
	if earned > 0:
		data.pending_income += earned
		data.offline_income += earned
		offline_income_received.emit(earned)
	data.last_saved_at = now


func _load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var loaded_data := ResourceLoader.load(SAVE_PATH) as EconomyData
		if is_instance_valid(loaded_data):
			data = loaded_data
			return
		push_error("EconomyTools: не удалось загрузить данные экономики.")
	else:
		_migrate_legacy_save()

	if data.last_saved_at <= 0:
		data.last_saved_at = int(Time.get_unix_time_from_system())


func _migrate_legacy_save() -> void:
	# Переносим сохранение из первой версии экономики на ConfigFile.
	const LEGACY_SAVE_PATH := "user://economy.cfg"
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return

	var config := ConfigFile.new()
	if config.load(LEGACY_SAVE_PATH) != OK:
		push_warning("EconomyTools: старое сохранение найдено, но прочитать его не удалось.")
		return

	data.balance = maxi(0, int(config.get_value("economy", "balance", 0)))
	data.pending_income = maxi(0, int(config.get_value("economy", "pending_income", 0)))
	data.income_per_minute = maxf(0.0, float(config.get_value("economy", "income_per_minute", 0.0)))
	data.automated_pool_paths = config.get_value("economy", "automated_pool_paths", PackedStringArray())
	data.last_saved_at = int(config.get_value("economy", "last_saved_at", 0))
	_save_data()


func _save_data() -> void:
	data.last_saved_at = int(Time.get_unix_time_from_system())
	var error := ResourceSaver.save(data, SAVE_PATH)
	if error != OK:
		push_error("EconomyTools: ошибка сохранения данных экономики: %s" % error)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_data()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_apply_offline_income()
		updated.emit(balance, pending_income, income_per_minute)
