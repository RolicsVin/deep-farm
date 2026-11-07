## Модуль экономики. Создаётся ядром через Core._make_tool().
## Не работает с файловой системой: данные получает от ядра и возвращает ядру.
class_name EconomyTools extends Node

signal updated(balance: int, pending_income: int, income_per_minute: float)
signal offline_income_received(amount: int)

var data: EconomyData = EconomyData.new()
var _registered_pools: Array[Pool] = []
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


func _process(delta: float) -> void:
	if income_per_minute <= 0.0:
		return

	_fractional_income += income_per_minute * delta / 60.0
	var whole_income := int(floor(_fractional_income))
	if whole_income > 0:
		data.pending_income += whole_income
		_fractional_income -= whole_income
		updated.emit(balance, pending_income, income_per_minute)


func register_pool(pool: Pool) -> void:
	if not is_instance_valid(pool) or _registered_pools.has(pool):
		return

	_registered_pools.append(pool)
	if not pool.state_change.is_connected(_on_pool_state_changed):
		pool.state_change.connect(_on_pool_state_changed.bind(pool))
	if not pool.tree_exiting.is_connected(unregister_pool.bind(pool)):
		pool.tree_exiting.connect(unregister_pool.bind(pool))
	_recalculate_income()


func unregister_pool(pool: Pool) -> void:
	_registered_pools.erase(pool)
	_recalculate_income()


func _on_pool_state_changed(_state: Pool.states, _pool: Pool) -> void:
	_recalculate_income()


func _recalculate_income() -> void:
	var new_income := 0.0
	for pool in _registered_pools:
		if not is_instance_valid(pool) or pool.get_state() != Pool.states.NORMAL:
			continue
		new_income += _get_pool_income(pool)

	data.income_per_minute = new_income
	updated.emit(balance, pending_income, income_per_minute)


func collect_income() -> int:
	var collected := pending_income
	if collected <= 0:
		return 0

	data.balance += collected
	data.pending_income = 0
	updated.emit(balance, pending_income, income_per_minute)
	return collected


## Ядро вызывает этот метод при сохранении и включает результат в общий файл.
func get_save_data() -> EconomyData:
	data.pool_states.clear()
	data.automated_pool_paths.clear()

	for pool in _registered_pools:
		if not is_instance_valid(pool):
			continue
		var pool_path := str(pool.get_path())
		data.pool_states[pool_path] = pool.get_save_data()
		if pool.get_state() == Pool.states.NORMAL:
			data.automated_pool_paths.append(pool_path)

	return data


## Ядро передаёт сюда данные модуля и время, прошедшее с последнего сохранения.
func load_data(saved_data: Resource, offline_seconds: int = 0) -> void:
	if saved_data is EconomyData:
		data = saved_data as EconomyData
	else:
		data = EconomyData.new()

	var legacy_rate := maxf(0.0, data.income_per_minute)
	var has_pool_snapshots := not data.pool_states.is_empty()
	var offline_earned := 0.0

	for pool in _registered_pools:
		if not is_instance_valid(pool):
			continue

		var pool_path := str(pool.get_path())
		if has_pool_snapshots and data.pool_states.has(pool_path):
			var pool_snapshot: Dictionary = data.pool_states[pool_path]
			var saved_state := int(pool_snapshot.get("state", Pool.states.RECOVERED))
			var remaining := maxf(0.0, float(pool_snapshot.get("stabilization_remaining", 0.0)))
			var fish_income := _get_pool_income(pool)

			if saved_state == Pool.states.NORMAL:
				offline_earned += fish_income * float(offline_seconds) / 60.0
				pool.restore_saved_state(Pool.states.NORMAL, 0.0, pool_snapshot)
			elif saved_state == Pool.states.STABILISATION:
				if float(offline_seconds) >= remaining:
					offline_earned += fish_income * (float(offline_seconds) - remaining) / 60.0
					pool.restore_saved_state(Pool.states.NORMAL, 0.0, pool_snapshot)
				else:
					pool.restore_saved_state(Pool.states.STABILISATION, remaining - float(offline_seconds), pool_snapshot)
			else:
				pool.restore_saved_state(saved_state, 0.0, pool_snapshot)
		elif not has_pool_snapshots and data.automated_pool_paths.has(pool_path):
			# Старый формат хранил только список работающих бассейнов и общую ставку.
			pool.restore_saved_state(Pool.states.NORMAL, 0.0)

	if not has_pool_snapshots and offline_seconds > 0:
		offline_earned = legacy_rate * float(offline_seconds) / 60.0

	var earned := int(floor(offline_earned))
	if earned > 0:
		data.pending_income += earned
		data.offline_income += earned
		offline_income_received.emit(earned)

	data.last_saved_at = int(Time.get_unix_time_from_system())
	_recalculate_income()
	updated.emit(balance, pending_income, income_per_minute)


func _get_pool_income(pool: Pool) -> float:
	var result := 0.0
	for child in pool.get_children():
		if child is Fish:
			result += maxi(0, child.money)
	return result
