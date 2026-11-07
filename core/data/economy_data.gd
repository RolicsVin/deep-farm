## Данные, принадлежащие модулю экономики.
class_name EconomyData extends Resource

@export var balance: int = 0
@export var pending_income: int = 0
@export var income_per_minute: float = 0.0
@export var offline_income: int = 0
@export var automated_pool_paths: PackedStringArray = PackedStringArray()
@export var last_saved_at: int = 0
