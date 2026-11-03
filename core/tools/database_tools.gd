class_name DatabaseTools extends Node


# ниже просто пример с кодом, это не функции для работы
var db := SQLite.new()


func _ready() -> void:
	pass


func test():
	db.path = "user://save.db"
	db.open_db()
	db.query("CREATE TABLE IF NOT EXISTS player (id INTEGER PRIMARY KEY, hp INTEGER, pos_x REAL, pos_y REAL);")


func save_player(hp: int, pos: Vector2) -> void:
	db.query("BEGIN;")
	db.query_with_bindings(
		"INSERT OR REPLACE INTO player (id, hp, pos_x, pos_y) VALUES (1, ?, ?, ?);",
		[hp, pos.x, pos.y]
		)
	db.query("COMMIT;")
