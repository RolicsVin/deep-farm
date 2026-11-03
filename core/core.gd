## Ядро игры
extends Node

var _buffer: Dictionary = {}

# Модули



func _ready() -> void:
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
