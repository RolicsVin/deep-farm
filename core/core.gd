## Ядро игры.
## Объединяет инструменты и игровые модули.
## Общие игровые данные хранятся в отдельном синглтоне Data.
## Каждый модуль создаётся через _make_tool и хранит собственные данные в Resource.
extends Node

var _buffer: Dictionary = {}

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


func save_data():
	pass


func load_data():
	pass


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
