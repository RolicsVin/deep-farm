## Клас рыб. 
## Реализует поведение рыбы. 
## Хранит в себе константы, необходимые для жизнеспособности рыбы. 
## Если рыбе нехватает одного параметра в среде, то она повреждена. 
## Если рыбе нехватает более одного параметра в среде, то она мертва,
## но может ожить, если востановить среду (магия).
class_name Fish extends Entitie

const REQUIRED_TEMPERATURE = 20 ## Необходимая температура для жизнедеятельности
const REQUIRED_FILTRATION = 0.9 ## Индекс необходимой фильтрации воды для жизнедеятельности
const REQUIRED_OXYGEN = 0.98 ## Индекс необходимого кислорода для жизнедеятельности
const REQUIRED_FEEDING = 5 ## Необходимое кормление для жизнедеятельности


enum states {NORMAl, DAMAGET, DEAD}
var current_state = states.NORMAl

@export var brain_timer: Timer
@export var pool: Pool

var next_pos: Vector3


func _ready() -> void:
	# Настройка таймера
	brain_timer.wait_time = randf_range(5, 10)
	brain_timer.one_shot = true
	brain_timer.timeout.connect(choise)
	brain_timer.start(1)


func update_state() -> void: ## Обновление состояния рыбы
	# подсчёт нарушений
	var counter: int = 0
	
	if pool.curent_temperature < REQUIRED_TEMPERATURE:
		counter += 1
	
	if pool.curent_filtration < REQUIRED_FILTRATION:
		counter += 1
	
	if pool.curent_oxygen < REQUIRED_OXYGEN:
		counter += 1
	
	if pool.curent_feeding < REQUIRED_FEEDING:
		counter += 1
	
	# установка состояния
	if counter == 0:
		current_state = states.NORMAl
	
	elif counter == 1:
		current_state = states.DAMAGET
	
	elif counter > 1:
		current_state = states.DEAD


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	update_state() # обновляем состояние
	fish_logic(delta) # вызываем основную логику класса


func fish_logic(delta: float) -> void:
	match current_state:
		states.NORMAl:
			# Логика при нормальном состоянии
			global_position = position.move_toward(next_pos, speed * delta)
		
		states.DAMAGET:
			# Логика, когда рыба поврежденна
			global_position = position.move_toward(next_pos, (speed / 2) * delta)
		
		states.DEAD:
			# Логика, когда рыба мертва
			global_position.y = move_toward( # всплывает вверх
				global_position.y,
				pool.pool_colision.global_position.y + (pool.pool_colision.shape.size.y / 2),
				(speed / 2) * delta
				)
	
	# поворот
	pass # было бы круто реализовать отслеживание изменение позиции и поворачивать рыбу в сторону движения


func choise() -> void:
	# Тут будет делатся выбор, куда рыба будет плыть дальше
	next_pos = pool.pick_random_point()
	
	# Новый запуск таймера
	brain_timer.start(randf_range(5, 10))
