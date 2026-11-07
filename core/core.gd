## Ядро игры.
## Объединяет инструменты и игровые модули, а также централизованно управляет сохранениями.
extends Node

const SAVE_PATH := "user://save_data.tres"
const LEGACY_ECONOMY_SAVE_PATH := "user://economy_data.tres"
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
	# Автозагрузка Core выполняется раньше основной сцены.
	# Даём сцене Map и её бассейнам завершить _ready(), прежде чем раздавать сохранённые данные.
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
	var save_resource := CoreSaveData.new()
	save_resource.saved_at = int(Time.get_unix_time_from_system())

	for module in _get_modules():
		save_resource.modules[module.name] = module.get_save_data()

	var error := ResourceSaver.save(save_resource, SAVE_PATH)
	if error != OK:
		push_error("Core: не удалось сохранить игру. Код ошибки: %s" % error)


func load_data() -> void:
	var save_resource: CoreSaveData
	var elapsed: int = 0

	if ResourceLoader.exists(SAVE_PATH):
		save_resource = ResourceLoader.load(SAVE_PATH) as CoreSaveData
		if not is_instance_valid(save_resource):
			push_error("Core: файл сохранения повреждён или имеет неверный формат.")
			return
		elapsed = maxi(0, int(Time.get_unix_time_from_system()) - save_resource.saved_at)
	else:
		# Однократная совместимость с прежним сохранением экономики.
		var legacy_data := ResourceLoader.load(LEGACY_ECONOMY_SAVE_PATH) as EconomyData
		if is_instance_valid(legacy_data):
			save_resource = CoreSaveData.new()
			save_resource.saved_at = legacy_data.last_saved_at
			save_resource.modules["Economy"] = legacy_data
			elapsed = maxi(0, int(Time.get_unix_time_from_system()) - legacy_data.last_saved_at)
		else:
			save_resource = CoreSaveData.new()

	for module in _get_modules():
		module.load_data(save_resource.modules.get(module.name), elapsed)

	_data_loaded = true
	save_data()


func _notification(what: int) -> void:
	if not _data_loaded:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_data()


func _print_log():
	print("Печатает ядро игры. (core.gd)")


func _get_obj_on_buffer(k):
	return _buffer[k]


func _get_buffer() -> Dictionary:
	return _buffer


func _write_buffer(obj, k) -> void:
	_buffer[k] = obj


func clear_buffer() -> void:
	_buffer.clear()


func push_fatal_error(message: String):
	print(message)
	push_error(message)
	Engine.get_main_loop().quit()
