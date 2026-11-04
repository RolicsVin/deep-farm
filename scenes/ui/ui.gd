## Скрипт для изменения состояние бассейна. 
extends Control


var pool: Pool


func _ready() -> void:
	# Поднимаем инструменты выше экрана
	position.y = Core.window_tools.get_screen_size().y


func set_pool(_pool: Pool) -> void: ## Установит бассейн для редактирвоания
	pool = _pool
	
	# Установка значений
	$Panel/VBoxContainer/t.value = pool.curent_temperature
	$Panel/VBoxContainer/filter.value = pool.curent_filtration
	$Panel/VBoxContainer/o.value = pool.curent_oxygen
	$Panel/VBoxContainer/feething.value = pool.curent_feeding


func set_temperature(t: int): ## Установит температуру для текущего бассейна
	pool.curent_temperature = int(t)


func set_filtration(f: float): ## Установит фильтрацию для текущего бассейна
	pool.curent_filtration = f / 100


func set_oxygen(o: float): ## Установит кислород для текущего бассейна
	pool.curent_oxygen = o / 100


func set_feeding(f: int): ## Установит кормление для текущего бассейна
	pool.curent_feeding = int(f)
