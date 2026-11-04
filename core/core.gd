## Ядро игры. 
## Объединяет в себе инструменты и реализует некоторые свои функции. 
## Данные в ядре не хранятся. Для этого есть модуль общий синглтон Data. 

## Об общем модуле Data
## Это общая Data - она отдельным синглтоном. Там хранятся общие игровые данные. Например настройки

## Как устроены модули. 
## Каждый модуль = 1 синглтон. 
## Для каждого модуля своя Data. Data для модуля не должна быть отдельным синглтоном.
## Data для модуля должна быть реализована через Resource. 
extends Node

var _buffer: Dictionary = {} ## буффер игры

# Модули
var tools: GTTools = _make_tool("res://core/tools/tools.gd", "Tools") ## Различные нструменты
var window_tools: WindowTools = _make_tool("res://core/tools/window_tools.gd", "WindowTools") ## Инструменты для окна
var time_tools: TimeTools = _make_tool("res://core/tools/time_tools.gd", "TimeTools") ## Инструменты для времени
var scene_tools: SceneTools = _make_tool("res://core/tools/scene_tools.gd", "SceneTools") ## Инструменты для сцены
var platform_tools: PlatformTools = _make_tool("res://core/tools/platform_tools.gd", "PlatformTools") ## Инструменты для платформы
var database_tools: DatabaseTools = _make_tool("res://core/tools/database_tools.gd", "DatabaseTools") ## Инструменты для SQLite


func _make_tool(path: String, tool_name: String) -> Node:
	var node: Node = load(path).new()
	node.name = tool_name
	add_child(node)
	return node


func save_data(): ## сделает сохранение
	pass


func load_data(): ## загрузит сохранение
	pass


func _print_log(): ## Предупредит, что сейчас печатает ядро игры.
	print('Печатает ядро игры. (core.gd)')


func _get_obj_on_buffer(k): ## Вернёт объект из буфера по ключу.
	return _buffer[k]


func _get_buffer() -> Dictionary: ## Вернёт буффер модуля godo_visual_novel.
	return _buffer


func _write_buffer(obj, k) -> void: ## Допишет в буфер информацию по ключу. Если ключ уже существует, то информация будет перезаписана.
	_buffer[k] = obj


func clear_buffer() -> void: ## Очистит буфер.
	"""Очистит буфер."""


func push_fatal_error(message: String): ## Выведет сообщение об ошибке, через print и push_error. После вывода ошибки обрушит проект.
	print(message)
	push_error(message)
	Engine.get_main_loop().quit()
