## Класс, реализующий логику бассейна. Смотрите README.md в разделе 2. Геймдизайн. 
## Бассейн хранит в себе рыбок. Если с бассейном всё хорошо он даёт деньги, инче не даёт. 
## Если что-то не так это визуально отображается на бассейне. 
class_name Pool extends Node3D

enum states {DEFEAT, STABILISATION, NORMAL} ## виды состояний бассейна

@export var money: int ## Монеты, которые будет приносить бассейн

@export var curent_state: states = states.DEFEAT ## Состояние бассейна

@export_group('characteristics')
@export var curent_temperature: int = 20 ## Текущая температура в бассейне
@export var curent_filtration: float = 0.9 ## Индекс фильтрация грязи
@export var curent_oxygen: float = 0.98 ## Индекс количества кислорода в воде
@export var curent_feeding: int = 5 ## Текущая подача питания в бассейне

@export_group('dependies')
@export var camera_pos: Marker3D ## Куда будет двигатся камера
@export var pool_colision: CollisionShape3D ## Область, в пределах которой может передвигатся рыба

@export var water: MeshInstance3D ## меш воды
@export var pool_timer: Timer ## таймер


func _ready() -> void:
	if not pool_colision.shape is BoxShape3D:
		Core.push_fatal_error('Класс Pool поддерживает только BoxShape3D. Другие виды форм не поддерживаются.')
	
	# Настройки таймера
	pool_timer.one_shot = true
	pool_timer.stop()


func _process(delta: float) -> void:
	# Логика при состоянии
	match curent_state:
		states.DEFEAT:
			# Разрушен
			pass
		states.STABILISATION:
			# Стабилизируется
			pass
		states.NORMAL:
			# В порядке
			pass
	
	# Обновление вида бассейна в соответствии с симптомами
	pass # типо какая-то логика на будущее


func pick_random_point() -> Vector3:
	return Vector3(
		randf_range(-pool_colision.shape.size.x / 2, pool_colision.shape.size.x / 2),
		randf_range(-pool_colision.shape.size.y / 2, pool_colision.shape.size.y / 2),
		randf_range(-pool_colision.shape.size.z / 2, pool_colision.shape.size.z / 2)
	) + pool_colision.global_position


func get_state() -> states:
	return curent_state


func spawn_fish() -> void: ## создаст рыбу в бассейне
	pass
