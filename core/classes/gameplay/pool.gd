class_name Pool extends Node3D

enum states {DEFEAT, STABILISATION, NORMAL}
enum symptoms {NONE, TRUSH, OVERHEATED, FROZEN}

@export var curent_state: states = states.DEFEAT
@export var curent_symptom: symptoms = symptoms.NONE

@export var camera_pos: Marker3D ## Куда будет двигатся камера
@export var pool_colision: CollisionShape3D ## Область, в пределах которой может передвигатся рыба.


func _ready() -> void:
	if not pool_colision.shape is BoxShape3D:
		Core.push_fatal_error('Класс Pool поддерживает только BoxShape3D. Другие виды форм не поддерживаются.')


func pick_random_point() -> Vector3:
	return Vector3(
		randf_range(-pool_colision.shape.size.x / 2, pool_colision.shape.size.x / 2),
		randf_range(-pool_colision.shape.size.y / 2, pool_colision.shape.size.y / 2),
		randf_range(-pool_colision.shape.size.z / 2, pool_colision.shape.size.z / 2)
	)


func get_state() -> states:
	return curent_state


func get_symptom() -> symptoms:
	return curent_symptom
