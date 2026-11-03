@abstract
class_name Entitie extends CharacterBody3D

@export var speed: float = 1.0

var to_position: Vector3
var is_moving_to: bool = false


func _physics_process(delta: float) -> void:
	if is_moving_to:
		position.move_toward(to_position, speed * delta)
		if position == to_position:
			is_moving_to = false


func move_to(to: Vector3): ## Двигает тело в опередлённую позицию
	to_position = to
	is_moving_to = true
