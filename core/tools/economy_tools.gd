## Модуль экономики. Создаётся ядром через Core._make_tool().
## Не обращается к файловой системе или SQL: только передаёт ядру данные.
class_name EconomyTools extends Node

signal updated(balance: int, pending_income: int, income_per_minute: float)
signal offline_income_received(amount: int)

var data: Dictionary = {
	"balance": 0,
	"pending_income": 0,
	"offline_income": 0,
	"pool_states": {}
}
var _registered_pools: Array[Pool] = []
var _fractional_income: float = 0.0

var balance: int:
	get:
		return int(data.get("balance", 0))

var pending_income: int:
	get:
		return int(data.get("pending_income", 0))

var income_per_minute: float:
	get:
		return float(data.get("income_per_minute", 0.0))

var offline_income: int:
	get:
		return int(data.get("offline_income", 0))


func _process(delta: float) -> void:
	if income_per_minute <= 0.0:
		return

	_fractional_income += income_per_minute * delta / 60.0
	var whole_income := int(floor(_fractional_income))
	if whole_income > 0:
		data["pending_income"] = pending_income + whole_income
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

	data["income_per_minute"] = new_income
	updated.emit(balance, pending_income, income_per_minute)


func collect_income() -> int:
	var collected := pending_income
	if collected <= 0:
		return 0

	data["balance"] = balance + collected
	data["pending_income"] = 0
	updated.emit(balance, pending_income, income_per_minute)
	return collected


## Ядро получает эти данные и сохраняет их в SQLite.
func get_save_data() -> Dictionary:
	var pool_states: Dictionary = {}
	for pool in _registered_pools:
		if not is_instance_valid(pool):
			continue
		pool_states[str(pool.get_path())] = pool.get_save_data()

	return {
		"balance": balance,
		"pending_income": pending_income,
		"offline_income": offline_income,
		"pool_states": pool_states
	}


## Ядро передаёт данные из SQLite и длительность отсутствия игрока.
func load_data(saved_data: Variant, offline_seconds: int = 0) -> void:
	if saved_data is Dictionary:
		data["balance"] = int(saved_data.get("balance", 0))
		data["pending_income"] = int(saved_data.get("pending_income", 0))
		data["offline_income"] = int(saved_data.get("offline_income", 0))
		data["pool_states"] = saved_data.get("pool_states", {})
	else:
		data["balance"] = 0
		data["pending_income"] = 0
		data["offline_income"] = 0
		data["pool_states"] = {}

	var saved_pool_states: Dictionary = data.get("pool_states", {})
	var offline_earned := 0.0

	for pool in _registered_pools:
		if not is_instance_valid(pool):
			continue

		var pool_path := str(pool.get_path())
		if not saved_pool_states.has(pool_path):
			continue

		var pool_snapshot: Dictionary = saved_pool_states[pool_path]
		var saved_state: Pool.states = int(pool_snapshot.get("state", Pool.states.RECOVERED))
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

	var earned := int(floor(offline_earned))
	if earned > 0:
		data["pending_income"] = pending_income + earned
		data["offline_income"] = offline_income + earned
		offline_income_received.emit(earned)

	_recalculate_income()
	updated.emit(balance, pending_income, income_per_minute)


func _get_pool_income(pool: Pool) -> float:
	var result := 0.0
	for child in pool.get_children():
		if child is Fish:
			result += maxi(0, child.money)
	return result
