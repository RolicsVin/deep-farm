## Централизованный доступ к SQLite.
## Только ядро вызывает методы сохранения и загрузки игровых данных.
class_name DatabaseTools extends Node

const DATABASE_PATH := "user://deep_farm.db"

var db: SQLite = SQLite.new()
var is_open: bool = false


func _ready() -> void:
	open_database()


func open_database() -> bool:
	if is_open:
		return true

	db.path = DATABASE_PATH
	if not db.open_db():
		push_error("DatabaseTools: не удалось открыть SQLite базу: %s" % DATABASE_PATH)
		return false

	is_open = true
	if not db.query("""
		CREATE TABLE IF NOT EXISTS game_save (
			id INTEGER PRIMARY KEY CHECK (id = 1),
			saved_at INTEGER NOT NULL,
			modules_json TEXT NOT NULL
		);
	"""):
		push_error("DatabaseTools: не удалось создать таблицу game_save.")
		db.close_db()
		is_open = false
		return false

	return true


func save_game_data(modules: Dictionary, saved_at: int) -> bool:
	if not open_database():
		return false

	var modules_json := JSON.stringify(modules)
	if not db.query("BEGIN TRANSACTION;"):
		push_error("DatabaseTools: не удалось начать транзакцию сохранения.")
		return false

	var query_ok := db.query_with_bindings(
		"INSERT OR REPLACE INTO game_save (id, saved_at, modules_json) VALUES (1, ?, ?);",
		[saved_at, modules_json]
	)

	if not query_ok:
		db.query("ROLLBACK;")
		push_error("DatabaseTools: не удалось записать данные игры.")
		return false

	if not db.query("COMMIT;"):
		db.query("ROLLBACK;")
		push_error("DatabaseTools: не удалось завершить транзакцию сохранения.")
		return false

	return true


func load_game_data() -> Dictionary:
	if not open_database():
		return {}

	if not db.query("SELECT saved_at, modules_json FROM game_save WHERE id = 1;"):
		push_error("DatabaseTools: ошибка чтения сохранения.")
		return {}

	if db.query_result.is_empty():
		return {}

	var row: Dictionary = db.query_result[0]
	var json := JSON.new()
	var parse_error := json.parse(str(row.get("modules_json", "{}")))
	if parse_error != OK or not json.data is Dictionary:
		push_error("DatabaseTools: сохранение содержит некорректный JSON.")
		return {}

	return {
		"saved_at": int(row.get("saved_at", 0)),
		"modules": json.data
	}


func close_database() -> void:
	if not is_open:
		return
	db.close_db()
	is_open = false
