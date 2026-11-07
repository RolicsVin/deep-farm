## Экономика игры: баланс, накопленный доход и офлайн-прогресс.
extends Node

signal updated(balance: int, pending_income: int, income_per_minute: float)
signal offline_income_received(amount: int)

const SAVE_PATH := "user://economy.cfg"
const SAVE_INTERVAL := 15.0

var balance: int = 0
var pending_income: int = 0
var income_per_minute: float = 0.0
var offline_income: int = 0

var _fractional_income: float = 0.0
var _registered_pools: Array[Pool] = []
var _save_elapsed: float = 0.0
var _last_saved_at: int = 0


func _ready() -> void:
	_load_save()
	_apply_offline_income()
	updated.emit(balance, pending_income, income_per_minute)


func _process(delta: float) -> void:
	if income_per_minute > 0.0:
		_fractional_income += income_per_minute * delta / 60.0
		var whole_income := int(floor(_fractional_income))
		if whole_income > 0:
			pending_income += whole_income
			_fractional_income -= whole_income
			updated.emit(balance, pending_income, income_per_minute)

	_save_elapsed += delta
	if _save_elapsed >= SAVE_INTERVAL:
		_save_elapsed = 0.0
		_save()


func register_pool(pool: Pool) -> void:
	if not is_instance_valid(pool) or _registered_pools.has(pool):
		return

	_registered_pools.append(pool)
	if not pool.state_change.is_connected(_on_pool_state_changed):
		pool.state_change.connect(_on_pool_state_changed)
	pool.tree_exiting.connect(unregister_pool.bind(pool))
	_recalculate_income()


func unregister_pool(pool: Pool) -> void:
	_registered_pools.erase(pool)
	_recalculate_income()


func _on_pool_state_changed(_state: Pool.states) -> void:
	_recalculate_income()


func _recalculate_income() -> void:
	var new_income := 0.0

	for pool in _registered_pools:
		if not is_instance_valid(pool) or pool.get_state() != Pool.states.NORMAL:
			continue

		for child in pool.get_children():
			if child is Fish:
				new_income += maxi(0, child.money)

	income_per_minute = new_income
	updated.emit(balance, pending_income, income_per_minute)


func collect_income() -> int:
	var collected := pending_income
	if collected <= 0:
		return 0

	balance += collected
	pending_income = 0
	updated.emit(balance, pending_income, income_per_minute)
	_save()
	return collected


func _apply_offline_income() -> void:
	var now := int(Time.get_unix_time_from_system())
	if _last_saved_at <= 0:
		_last_saved_at = now
		return

	var elapsed := maxi(0, now - _last_saved_at)
	var earned := int(floor(elapsed * income_per_minute / 60.0))
	if earned > 0:
		pending_income += earned
		offline_income += earned
		offline_income_received.emit(earned)

	_last_saved_at = now


func _load_save() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		_last_saved_at = int(Time.get_unix_time_from_system())
		return

	balance = maxi(0, int(config.get_value("economy", "balance", 0)))
	pending_income = maxi(0, int(config.get_value("economy", "pending_income", 0)))
	income_per_minute = maxf(0.0, float(config.get_value("economy", "income_per_minute", 0.0)))
	_last_saved_at = int(config.get_value("economy", "last_saved_at", 0))


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("economy", "balance", balance)
	config.set_value("economy", "pending_income", pending_income)
	config.set_value("economy", "income_per_minute", income_per_minute)
	config.set_value("economy", "last_saved_at", int(Time.get_unix_time_from_system()))

	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("Economy: не удалось сохранить экономику. Код ошибки: %s" % error)
	else:
		_last_saved_at = int(Time.get_unix_time_from_system())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_apply_offline_income()
		updated.emit(balance, pending_income, income_per_minute)
