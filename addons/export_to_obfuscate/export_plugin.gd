@tool
extends EditorExportPlugin


func _get_name() -> String:
	return "MyObfuscator"


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if type == "GDScript" and path.ends_with(".gd"):
		var original_code := FileAccess.get_file_as_string(path)
		var obfuscated_code := _obfuscate(original_code)  # ваша логика
		skip()  # отменяем добавление оригинального файла
		add_file(path, obfuscated_code.to_utf8_buffer(), false)


func _obfuscate(code: String) -> String:
	# например, переименование локальных переменных, удаление комментариев и т.п.
	return code
