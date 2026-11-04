## Класс, реализующий логику бассейна. Смотрите README.md в разделе 2. Геймдизайн. 
## Бассейн хранит в себе рыбок. Если с бассейном всё хорошо он даёт деньги, иначе не даёт. 
## Если что-то не так это визуально отображается на бассейне. 

## DEFEAT - Разрушен. Дохода нет. 
## RECOVERED - Востановлен. Доход маленький. 
## STABILISATION - Стабилизируется. 
## NORMAL - В норме. Доход полный. 
class_name Pool extends Node3D

enum states {DEFEAT, RECOVERED, STABILISATION, NORMAL} ## виды состояний бассейна

@export var curent_state: states = states.RECOVERED ## Состояние бассейна

@export_group('characteristics')
@export var curent_temperature: int = 20 ## Текущая температура в бассейне
@export var curent_filtration: float = 0.9 ## Индекс фильтрация грязи
@export var curent_oxygen: float = 0.98 ## Индекс количества кислорода в воде
@export var curent_feeding: int = 5 ## Текущая подача питания в бассейне

@export var time_stabilization: int = 600 ## Время стабилизации в сек.

@export_group('dependies')
@export var camera_pos: Marker3D ## Куда будет двигатся камера
@export var pool_colision: CollisionShape3D ## Область, в пределах которой может передвигатся рыба

@export var water: MeshInstance3D ## меш воды
@export var pool_timer: Timer ## таймер

signal state_change(state: Pool.states) ## Издаётся при смене состояния
signal reovered ## Издаётся, когда бассейн востановлен


func _ready() -> void:
	if not pool_colision.shape is BoxShape3D:
		Core.push_fatal_error('Класс Pool поддерживает только BoxShape3D. Другие виды форм не поддерживаются.')
	
	# Настройки таймера
	pool_timer.one_shot = true
	pool_timer.stop()
	pool_timer.timeout.connect(_make_stable)


func _process(_delta: float) -> void:
	# Логика при состоянии
	match curent_state:
		states.DEFEAT:
			# Проверка на возможность востановления
			
			# подсчёт нарушений
			var counter: int = 0
			
			if curent_temperature < Fish.REQUIRED_TEMPERATURE:
				counter += 1
			
			if curent_filtration < Fish.REQUIRED_FILTRATION:
				counter += 1
			
			if curent_oxygen < Fish.REQUIRED_OXYGEN:
				counter += 1
			
			if curent_feeding < Fish.REQUIRED_FEEDING:
				counter += 1
			
			# установка состояния
			if counter == 0:
				curent_state = states.RECOVERED
				state_change.emit(curent_state)
		
		states.RECOVERED:
			# Восстановлен
			pass
		
		states.NORMAL:
			# В порядке
			pass
	
	# Обновление вида бассейна в соответствии с симптомами
	pass # типо какая-то логика на будущее


func pick_random_point() -> Vector3: ## Вернёт случайную точку из бассейна в глобальных координатах
	return Vector3(
		randf_range(-pool_colision.shape.size.x / 2, pool_colision.shape.size.x / 2),
		randf_range(-pool_colision.shape.size.y / 2, pool_colision.shape.size.y / 2),
		randf_range(-pool_colision.shape.size.z / 2, pool_colision.shape.size.z / 2)
	) + pool_colision.global_position


func get_state() -> states: ## Вернёт состояние бассейна
	return curent_state


func spawn_fish() -> void: ## создаст рыбу в бассейне
	pass


func start_stabilization() -> void: ## Начнёт стабилизирование бассейна
	curent_state = states.STABILISATION
	pool_timer.start(time_stabilization)


func _make_stable() -> void: ## Переведёт бассейн в стабильнео состояние
	curent_state = states.NORMAL
	state_change.emit(curent_state)
	reovered.emit()
