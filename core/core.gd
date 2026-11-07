## Ядро игры.
## Объединяет игровые модули и централизованно управляет SQL-сохранениями.
extends Node

const SAVE_INTERVAL := 15.0

var _buffer: Dictionary = {}
var _save_elapsed: float = 0.0
var _data_loaded: bool = false

# Инструменты
var tools: GTTools = _make_tool("res://core/tools/tools.gd", "Tools")
var window_tools: WindowTools = _make_tool("res://core/tools/window_tools.gd", "WindowTools")
var time_tools: TimeTools = _make_tool("res://core/tools/time_tools.gd", "TimeTools")
var scene_tools: SceneTools = _make_tool("res://core/tools/scene_tools.gd", "SceneTools")
var platform_tools: PlatformTools = _make_tool("res://core/tools/platform_tools.gd", "PlatformTools")
var database_tools: DatabaseTools = _make_tool("res://core/tools/database_tools.gd", "DatabaseTools")

# Игровые модули
var economy_tools: EconomyTools = _make_tool("res://core/tools/economy_tools.gd", "Economy")


func _make_tool(path: String, tool_name: String) -> Node:
	var node: Node = load(path).new()
	node.name = tool_name
	add_child(node)
	return node


func _ready() -> void:
	# Сцена Map и её бассейны должны завершить _ready() до загрузки модульных данных.
	call_deferred("_load_after_scene_ready")


func _load_after_scene_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	load_data()


func _process(delta: float) -> void:
	if not _data_loaded:
		return

	_save_elapsed += delta
	if _save_elapsed >= SAVE_INTERVAL:
		_save_elapsed = 0.0
		save_data()


func _get_modules() -> Array[Node]:
	var modules: Array[Node] = []
	for child in get_children():
		if child.has_method("get_save_data") and child.has_method("load_data"):
			modules.append(child)
	return modules


func save_data() -> void:
	var modules_data: Dictionary = {}
	for module in _get_modules():
		modules_data[module.name] = module.get_save_data()

	var saved_at := int(Time.get_unix_time_from_system())
	if not database_tools.save_game_data(modules_data, saved_at):
		push_error("Core: не удалось сохранить игровые данные в SQLite.")


func load_data() -> void:
	var save_record := database_tools.load_game_data()
	var modules_data: Dictionary = save_record.get("modules", {})
	var saved_at := int(save_record.get("saved_at", 0))
	var elapsed := 0

	if saved_at > 0:
		elapsed = maxi(0, int(Time.get_unix_time_from_system()) - saved_at)

	for module in _get_modules():
		module.load_data(modules_data.get(module.name, {}), elapsed)

	_data_loaded = true
	# Сразу фиксируем timestamp после расчёта офлайн-прогресса:
	# повторный вызов load_data не начислит тот же офлайн-доход повторно.
	save_data()


func _notification(what: int) -> void:
	if not _data_loaded:
		return

	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_data()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		load_data()


func _exit_tree() -> void:
	if is_instance_valid(database_tools):
		database_tools.close_database()


func _print_log() -> void:
	print("Печатает ядро игры. (core.gd)")


func _get_obj_on_buffer(k):
	return _buffer[k]


func _get_buffer() -> Dictionary:
	return _buffer


func _write_buffer(obj, k) -> void:
	_buffer[k] = obj


func clear_buffer() -> void:
	_buffer.clear()


func push_fatal_error(message: String) -> void:
	print(message)
	push_error(message)
	Engine.get_main_loop().quit()
