@tool
extends EditorPlugin

var hl := PyHighlighter.new()

func _enter_tree() -> void:
	EditorInterface.get_script_editor().register_syntax_highlighter(hl)

func _exit_tree() -> void:
	EditorInterface.get_script_editor().unregister_syntax_highlighter(hl)
