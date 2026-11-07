## Централизованный доступ к SQLite.
## Только ядро вызывает методы сохранения и загрузки игровых данных.
class_name DatabaseTools extends Node

const DATABASE_PATH := "user://deep_farm.db"

var db: SQLite = SQLite.new()
var is_open: bool = false
var last_load_success: bool = false


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

	var metadata_table_ok := db.query("""
		CREATE TABLE IF NOT EXISTS save_metadata (
			id INTEGER PRIMARY KEY CHECK (id = 1),
			saved_at INTEGER NOT NULL
		);
	""")
	var module_table_ok := db.query("""
		CREATE TABLE IF NOT EXISTS module_data (
			module_name TEXT PRIMARY KEY,
			data_json TEXT NOT NULL
		);
	""")

	if not metadata_table_ok or not module_table_ok:
		push_error("DatabaseTools: не удалось создать таблицы сохранения. " + db.error_message)
		db.close_db()
		is_open = false
		return false

	return true


func save_game_data(modules: Dictionary, saved_at: int) -> bool:
	if not open_database():
		return false

	if not db.query("BEGIN TRANSACTION;"):
		push_error("DatabaseTools: не удалось начать транзакцию сохранения. " + db.error_message)
		return false

	var metadata_ok := db.query_with_bindings(
		"INSERT OR REPLACE INTO save_metadata (id, saved_at) VALUES (1, ?);",
		[saved_at]
	)
	if not metadata_ok:
		db.query("ROLLBACK;")
		push_error("DatabaseTools: не удалось записать время сохранения. " + db.error_message)
		return false

	if not db.query("DELETE FROM module_data;"):
		db.query("ROLLBACK;")
		push_error("DatabaseTools: не удалось очистить старые данные модулей. " + db.error_message)
		return false

	for module_name in modules:
		var module_json := JSON.stringify(modules[module_name])
		var module_ok := db.query_with_bindings(
			"INSERT INTO module_data (module_name, data_json) VALUES (?, ?);",
			[str(module_name), module_json]
		)
		if not module_ok:
			db.query("ROLLBACK;")
			push_error("DatabaseTools: не удалось сохранить модуль '%s'. %s" % [module_name, db.error_message])
			return false

	if not db.query("COMMIT;"):
		db.query("ROLLBACK;")
		push_error("DatabaseTools: не удалось завершить транзакцию сохранения. " + db.error_message)
		return false

	return true


func load_game_data() -> Dictionary:
	last_load_success = false
	if not open_database():
		return {}

	if not db.query("SELECT saved_at FROM save_metadata WHERE id = 1;"):
		push_error("DatabaseTools: ошибка чтения метаданных сохранения. " + db.error_message)
		return {}

	if db.query_result.is_empty():
		last_load_success = true
		return {}

	var saved_at := int(db.query_result[0].get("saved_at", 0))
	if not db.query("SELECT module_name, data_json FROM module_data;"):
		push_error("DatabaseTools: ошибка чтения данных модулей. " + db.error_message)
		return {}

	var modules: Dictionary = {}
	for row in db.query_result:
		var module_name := str(row.get("module_name", ""))
		var json := JSON.new()
		var parse_error := json.parse(str(row.get("data_json", "{}")))
		if parse_error != OK or not json.data is Dictionary:
			push_error("DatabaseTools: некорректные данные модуля '%s'." % module_name)
			return {}
		modules[module_name] = json.data

	last_load_success = true
	return {
		"saved_at": saved_at,
		"modules": modules
	}


func close_database() -> void:
	if not is_open:
		return
	db.close_db()
	is_open = false
