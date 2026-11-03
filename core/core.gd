## Ядро игры. 
## Объединяет в себе инструменты и реализует некоторые свои функции. 
## Данные в ядре не хранятся. Для этого есть модуль Data. 
extends Node

var _buffer: Dictionary = {}

# Модули
var tools: GTTools = _make_tool("res://core/tools/tools.gd", "Tools")
var window_tools: WindowTools = _make_tool("res://core/tools/window_tools.gd", "WindowTools")
var time_tools: TimeTools = _make_tool("res://core/tools/time_tools.gd", "TimeTools")
var scene_tools: SceneTools = _make_tool("res://core/tools/scene_tools.gd", "SceneTools")
var platform_tools: PlatformTools = _make_tool("res://core/tools/platform_tools.gd", "PlatformTools")
var database_tools: DatabaseTools = _make_tool("res://core/tools/database_tools.gd", "DatabaseTools")


func _make_tool(path: String, tool_name: String) -> Node:
	var node: Node = load(path).new()
	node.name = tool_name
	add_child(node)
	return node


# функции ядра
func _ready() -> void:
	pass


func save(): ## сделает сохранение
	pass


func load_save(): ## загрузит сохранение
	pass


func _print_log(): ## Предупредит, что сейчас печатает ядро игры.
	print('Печатает ядро игры. (core.gd)')


func _get_obj_on_buffer(k): ## Вернёт объект из буфера по ключу.
	return _buffer[k]


func _get_buffer() -> Dictionary: ## Вернёт буффер модуля godo_visual_novel.
	return _buffer


func _write_buffer(obj, k) -> void: ## Допишет в буфер информацию по ключу. Если ключ уже существует, то информация будет перезаписана.
	_print_log()
	_buffer[k] = obj


func clear_buffer() -> void: ## Очистит буфер.
	"""Очистит буфер."""


func push_fatal_error(message: String): ## Выведет сообщение об ошибке, через print и push_error. После вывода ошибки обрушит проект.
	print('Печатает служба Godo Tools')
	print(message)
	push_error(message)
	Engine.get_main_loop().quit()
