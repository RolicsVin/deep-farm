@tool
class_name PyHighlighter
extends EditorSyntaxHighlighter

const KEYWORDS := ["def","class","if","elif","else","for","while","return","import",
	"from","as","with","try","except","finally","raise","lambda","pass","break",
	"continue","in","is","not","and","or","None","True","False","self"]

var _kw := RegEx.new()
var _num := RegEx.new()
var _str := RegEx.new()
var _com := RegEx.new()


func _init() -> void:
	_kw.compile("\\b(" + "|".join(PackedStringArray(KEYWORDS)) + ")\\b")
	_num.compile("\\b\\d+(\\.\\d+)?\\b")
	_str.compile("\"[^\"]*\"|'[^']*'")
	_com.compile("#.*$")


func _get_name() -> String:
	return "Python"


func _get_supported_languages() -> PackedStringArray:
	return PackedStringArray(["py"])


func _create() -> EditorSyntaxHighlighter:
	return PyHighlighter.new()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text := get_text_edit().get_line(line)
	var base := Color("d4d4d4")
	var colors: Array[Color] = []
	colors.resize(text.length())
	colors.fill(base)

	_paint(colors, _kw.search_all(text), Color("ff7085"))
	_paint(colors, _num.search_all(text), Color("a1ffe0"))
	_paint(colors, _str.search_all(text), Color("ffeda1"))
	_paint(colors, _com.search_all(text), Color("7f8a99"))  # последним, чтобы перекрывал

	var result := {}
	var prev := Color(0, 0, 0, 0)
	for i in colors.size():
		if i == 0 or colors[i] != prev:
			result[i] = {"color": colors[i]}
			prev = colors[i]
	return result


func _paint(colors: Array[Color], matches: Array[RegExMatch], c: Color) -> void:
	for m in matches:
		for i in range(m.get_start(), m.get_end()):
			colors[i] = c
