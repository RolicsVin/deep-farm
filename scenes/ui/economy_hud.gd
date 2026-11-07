## Экран баланса и накопленного дохода.
extends CanvasLayer

var _balance_label: Label
var _pending_label: Label
var _collect_button: Button
var _offline_label: Label


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16.0, 16.0)
	panel.custom_minimum_size = Vector2(230.0, 0.0)
	add_child(panel)

	var layout := VBoxContainer.new()
	panel.add_child(layout)

	_balance_label = Label.new()
	_balance_label.text = "Баланс: 0"
	layout.add_child(_balance_label)

	_pending_label = Label.new()
	_pending_label.text = "Накоплено: 0"
	layout.add_child(_pending_label)

	_offline_label = Label.new()
	_offline_label.visible = false
	layout.add_child(_offline_label)

	_collect_button = Button.new()
	_collect_button.text = "Забрать доход"
	_collect_button.pressed.connect(Economy.collect_income)
	layout.add_child(_collect_button)

	Economy.updated.connect(_update_display)
	_update_display(Economy.balance, Economy.pending_income, Economy.income_per_minute)

	if Economy.offline_income > 0:
		_offline_label.text = "За время отсутствия: +%d" % Economy.offline_income
		_offline_label.visible = true


func _update_display(current_balance: int, pending: int, rate: float) -> void:
	_balance_label.text = "Баланс: %s" % _format_amount(current_balance)
	_pending_label.text = "Накоплено: %s  (+%s/мин)" % [
		_format_amount(pending),
		_format_amount(int(round(rate)))
	]
	_collect_button.disabled = pending <= 0
	_collect_button.text = "Забрать доход (%s)" % _format_amount(pending)


func _format_amount(amount: int) -> String:
	return String.num_int64(amount)
