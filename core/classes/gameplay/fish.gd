class_name Fish extends Entitie

enum states {NORMAl, DEAD}
var current_state = states.NORMAl

@export var brain_timer: Timer
@export var pool: Pool

var next_pos: Vector3


func _ready() -> void:
	# Настройка таймера
	brain_timer.wait_time = randf_range(5, 10)
	brain_timer.one_shot = true
	brain_timer.timeout.connect(choise)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	match current_state:
		states.NORMAl:
			# Логика при нормальном состоянии
			position.move_toward(next_pos, speed * delta)
		
		states.DEAD:
			# Логика, когда рыба мертва
			pass


func choise() -> void:
	# Тут будет делатся выбор, куда рыба будет плыть дальше
	next_pos = pool.pick_random_point()
	
	# Новый запуск таймера
	brain_timer.start(randf_range(5, 10))
